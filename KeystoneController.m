#import "KeystoneController.h"

#import "CompletionServer.h"
#import "CompletionControllerAdditions.h"
#import "BrowserWindowControllerAdditions.h"

#import "AddCompletionController.h"
#import "BookmarksControllerAdditions.h"
#import "BrowserWindowController+JavaScript.h"
#import "UpdateController.h"
#import "DefaultsDomain.h"

#import "BookmarkSources.h"

#import <WebKit/WebKit.h>
#import <libkern/OSAtomic.h>
#import <Sparkle/SUUpdater.h>

static NSString * const kKeystonePreferencesDomain = @"com.belkadan.Keystone";
static NSString * const kPreferencesCompletionKey = @"SortedCompletions";
static NSString * const kPreferencesUntestedAlertSuppressionKey = @"SuppressUntestedAlert";
static NSString * const kPreferencesLoadUntestedKey = @"LoadUntested";
static NSString * const kPreferencesAutocompletionModeKey = @"AutocompleteMode";
static NSString * const kDefaultPreferencesFile = @"defaults"; // extension must be .plist

static NSString * const kAutodiscoverySearch = @"---Keystone---";
static NSString * const kKeystoneIconName = @"ComBelkadanKeystone_Preferences";

static NSString * const kSogudiCompletionsFile = @"SogudiShortcuts.plist";
static NSString * const kSogudiDefaultActionKeyword = @"default";
static NSString * const kSogudiSubstitutionMarker = @"@@@";

static const int kLatestSafariSystem = 7;
static const int kLatestTestedVersionOfSafari = 534;

#define kSafariVersionNumber5 533
static BOOL isSafari5 = NO;

enum {
	kAddButtonPosition = 0,
	kRemoveButtonPosition
};

@interface ComBelkadanKeystone_Controller () <NSUserInterfaceValidations, ComBelkadanKeystone_AddCompletionDelegate>
+ (BOOL)alertUntested;

- (BOOL)loadCompletions;
- (BOOL)loadSogudiCompletions;
- (void)loadDefaultCompletions;

- (void)alertSheetRequestDidEnd:(ComBelkadanKeystone_AlertSheetRequest *)sheetRequest returnCode:(NSInteger)returnCode unused:(void *)unused;

- (void)exportSettingsPanelDidEnd:(NSSavePanel *)savePanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused;
- (void)importSettingsPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused;
- (void)importSettingsFromURL:(NSURL *)url;
@end

@interface NSDocument (ComBelkadanKeystone_IKnowYoureInThere)
@property(readonly) NSString *URLString;
@property(readonly) NSURL *currentURL;

@property(readonly) NSWindowController *browserWindowControllerMac;
@property(readonly) NSWindowController *browserWindowController;
@end

@interface SUUpdater (ComBelkadanKeystone_IKnowYoureInThere)
- (void)applicationDidFinishLaunching:(NSNotification *)note; // only in older Sparkles
@end

static inline BOOL isOptionKeyDown ()
{
	CGEventRef tempEvent = CGEventCreate(NULL /*default event source*/);
	BOOL result = ((CGEventGetFlags(tempEvent) & kCGEventFlagMaskAlternate) != 0);
	CFRelease(tempEvent);
	return result;
}


@implementation ComBelkadanKeystone_Controller
@synthesize updater;

+ (void)load
{
	static NSImage *prefIcon = nil;
	if (!prefIcon) {
		prefIcon = [NSImage imageNamed:kKeystoneIconName];
		if (!prefIcon) {
			prefIcon = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"keystone"]];
			[prefIcon setName:kKeystoneIconName];
		}
	}

	[[NSClassFromString(@"WBPreferences") sharedPreferences] addPreferenceNamed:NSLocalizedStringFromTableInBundle(@"Keystone", @"Localizable", [NSBundle bundleForClass:[self class]], @"The preferences pane title") owner:[self sharedInstance]];

	int safariMajorVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] intValue];
	isSafari5 = (safariMajorVersion % 1000) >= kSafariVersionNumber5;

	BOOL shouldLoad = (safariMajorVersion % 1000) <= kLatestTestedVersionOfSafari;
	shouldLoad = shouldLoad && (safariMajorVersion / 1000) <= kLatestSafariSystem;
	
	if (!shouldLoad) {
		shouldLoad = [self alertUntested];
	}

	if (shouldLoad) {
		NSNumber *autocompleteMode = [[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] objectForKey:kPreferencesAutocompletionModeKey];
		if (autocompleteMode) {
			[ComBelkadanKeystone_CompletionServer setAutocompletionMode:[autocompleteMode unsignedIntegerValue]];
		}

		[ComBelkadanKeystone_CompletionServer addCompletionHandler:[self sharedInstance]];
		(void)[ComBelkadanKeystone_BookmarksControllerObjC class]; // force +initialize

		if (isSafari5) {
			(void)[ComBelkadanKeystone_BrowserWindowController class]; // force +initialize
		} else {
			(void)[ComBelkadanKeystone_URLCompletionController class]; // force +initialize
		}
		(void)[ComBelkadanKeystone_BrowserWindowController_JavaScript class]; // force +initialize
	}
}

- (id)init {
	if ((self = [super init])) {
		NSArray *descriptors = [[NSArray alloc] initWithObjects:
			[[[NSSortDescriptor alloc] initWithKey:@"keyword" ascending:YES] autorelease],
			[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease],
			[[[NSSortDescriptor alloc] initWithKey:@"URL" ascending:YES] autorelease],
			nil];
		sortedCompletionPossibilities = [[SortedArray alloc] initWithSortDescriptors:descriptors];
		[descriptors release];

		pendingConfirmations = [[NSMutableArray alloc] init];
		
		if (![self loadCompletions]) {
			if (![self loadSogudiCompletions]) {
				[self loadDefaultCompletions];
			}
		}
		
		updater = [[ComBelkadanKeystone_SparkleCompatibilityController updaterForBundle:[NSBundle bundleForClass:[self class]]] retain];
		if (updater) {
			[updater setDelegate:self];
			if ([updater respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
				// For older versions of Sparkle (through 1.5b6)
				[updater applicationDidFinishLaunching:nil];
			}
		}
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[sortedCompletionPossibilities release];
	[pendingConfirmations release];
	[updater release];
	[super dealloc];
}

+ (BOOL)alertUntested {
	NSBundle *keystoneBundle = [NSBundle bundleForClass:[ComBelkadanKeystone_Controller class]];
	NSString *currentVersion = [keystoneBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];

	BOOL isSuppressed = NO;
	BOOL shouldLoadAnyway = NO;

	ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain];
	NSString *suppressedVersion = [defaults objectForKey:kPreferencesUntestedAlertSuppressionKey];
	if (suppressedVersion) {
		isSuppressed = [suppressedVersion isEqual:currentVersion];
		if (isSuppressed) {
			shouldLoadAnyway = [[defaults objectForKey:kPreferencesLoadUntestedKey] boolValue];
		}
	}

	if (!isSuppressed || isOptionKeyDown()) {
		NSAlert *alert = [[NSAlert alloc] init];
		
		[alert setIcon:[NSImage imageNamed:kKeystoneIconName]];
		[alert setMessageText:NSLocalizedStringFromTableInBundle(@"Keystone is not yet supported in this version of Safari.", @"Localizable", keystoneBundle, @"Unsupported alert")];
		[alert setInformativeText:NSLocalizedStringFromTableInBundle(@"Check the Keystone preference pane for updates.", @"Localizable", keystoneBundle, @"Unsupported alert")];
		
		NSButton *continueButton = [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Load Keystone", @"Localizable", keystoneBundle, @"Unsupported alert")];
		[continueButton setKeyEquivalent:@""];
		NSButton *cancelButton = [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"Localizable", keystoneBundle, @"Unsupported alert")];
		[cancelButton setKeyEquivalent:@"\r"]; // Mac OS Classic lingers on...!
		
		[alert setShowsSuppressionButton:YES];
		NSButton *suppressionButton = [alert suppressionButton];
		[suppressionButton setTitle:NSLocalizedStringFromTableInBundle(@"Do not show this message again for this version", @"Localizable", keystoneBundle, @"Unsupported alert")];
		if (isSuppressed) [suppressionButton setState:NSOnState];
		
		NSInteger choice = [alert runModal];
		shouldLoadAnyway = (choice == [continueButton tag]);

		if ([suppressionButton state] == NSOnState) {
			[defaults setObject:currentVersion forKey:kPreferencesUntestedAlertSuppressionKey];
			[defaults setObject:[NSNumber numberWithBool:shouldLoadAnyway] forKey:kPreferencesLoadUntestedKey];
		} else if (suppressedVersion) {
			[defaults removeObjectForKey:kPreferencesUntestedAlertSuppressionKey];
		}
		[alert release];
	}
	
	return shouldLoadAnyway;
}

#pragma mark -

- (BOOL)loadCompletions {
	NSArray *completionsInPlistForm = [[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] objectForKey:kPreferencesCompletionKey];
	if (!completionsInPlistForm) return NO;
	
	for (NSDictionary *completionDict in completionsInPlistForm) {
		ComBelkadanKeystone_QueryCompletionItem *nextItem = [[ComBelkadanKeystone_QueryCompletionItem alloc] initWithDictionary:completionDict];
		if (nextItem) {
			[sortedCompletionPossibilities addObject:nextItem];
			[nextItem release];
		}
	}
	
	return YES;
}

- (BOOL)loadSogudiCompletions {
	NSString *appSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	NSDictionary *sogudiStyleCompletions = [[NSDictionary alloc] initWithContentsOfFile:[appSupportDirectory stringByAppendingPathComponent:kSogudiCompletionsFile]];
	if (!sogudiStyleCompletions) return NO;
	
	for (NSString *keyword in sogudiStyleCompletions) {
		ComBelkadanKeystone_QueryCompletionItem *nextItem;
		NSString *shortcutURL = [[sogudiStyleCompletions objectForKey:keyword]
			stringByReplacingOccurrencesOfString:kSogudiSubstitutionMarker withString:ComBelkadanKeystone_kSubstitutionMarker];
		
		if ([keyword isEqual:kSogudiDefaultActionKeyword]) {
			nextItem = [[ComBelkadanKeystone_QueryCompletionItem alloc]
				initWithName:NSLocalizedStringFromTableInBundle(@"(Default)", @"Localizable", [NSBundle bundleForClass:[self class]], @"A default action's name")
				keyword:@""
				shortcutURL:shortcutURL];
		} else {
			nextItem = [[ComBelkadanKeystone_QueryCompletionItem alloc] initWithName:keyword keyword:keyword shortcutURL:shortcutURL];
		}
		[sortedCompletionPossibilities addObject:nextItem];
		[nextItem release];
	}
	
	[sogudiStyleCompletions release];
	return YES;
}

- (void)loadDefaultCompletions {
	NSDictionary *defaults = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:kDefaultPreferencesFile ofType:@"plist"]];
	[[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] setDictionary:defaults];
	[defaults release];
	
	[self loadCompletions];
}

- (void)save {
	NSArray *completionsInPlistForm = [sortedCompletionPossibilities valueForKey:@"dictionaryRepresentation"];
	[[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] setObject:completionsInPlistForm forKey:kPreferencesCompletionKey];
}

#pragma mark -

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
	if ([item action] == @selector(attemptAutodiscovery:)) {
		NSDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
		id windowController;
		if ([doc respondsToSelector:@selector(browserWindowControllerMac)]) {
			windowController = [doc browserWindowControllerMac];
		} else {
			windowController = [doc browserWindowController];
		}
		
		if (![doc currentURL]) return NO;

		NSString *valid = [windowController ComBelkadanKeystone_evaluateBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1] javaScript:
			@"var ComBelkadanKeystone_status = false;"
			@"if (document && document.activeElement && document.activeElement.form) {"
				@"if (document.activeElement.nodeName == 'TEXTAREA') {"
					@"ComBelkadanKeystone_status = true;"
				@"} else if (document.activeElement.nodeName == 'INPUT') {"
					@"if (document.activeElement.type == 'text' || document.activeElement.type == 'search') {"
						@"ComBelkadanKeystone_status = true;"
					@"}"
				@"}"
			@"}"
			@"return ComBelkadanKeystone_status ? 'YES' : 'NO'"];

		// If we couldn't complete the JavaScript, /enable the menu anyway/.
		return valid ? [valid boolValue] : YES;

	} else if ([item action] == @selector(newCompletionForCurrentPage:)) {
		NSDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
		return [doc currentURL] != nil;

	} else {
		return YES;
	}
}

- (IBAction)attemptAutodiscovery:(id)sender {
	NSDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
	id windowController;
	if ([doc respondsToSelector:@selector(browserWindowControllerMac)]) {
		windowController = [doc browserWindowControllerMac];
	} else {
		windowController = [doc browserWindowController];
	}
	
	NSString *formURLString = [windowController ComBelkadanKeystone_evaluateBeforeDate:[NSDate dateWithTimeIntervalSinceNow:4] javaScript:
		@"if (document && document.activeElement && document.activeElement.form) {"
			@"var form = document.activeElement.form;"
			@"if ('' == form.method || 'get' == form.method.toLowerCase()) {"
				@"var old = document.activeElement.value;"
				@"document.activeElement.value = '---Keystone---';"
				@"var action = '';"
				@"if (form.action != '' && form.action[0] != '#') {"
					@"action = form.action;"
				@"}"
				@"action += '?';"
				@"for (var i = 0; i < form.elements.length; ++i) {"
					@"var elem = form.elements[i];"
					@"if (!elem.name) continue;"
					@"if (elem.type == 'button' || elem.type == 'file' || "
						@"elem.type == 'reset' || elem.type == 'submit' ||" // FIXME: <submit>
						@"elem.type == 'select-one' || elem.type == 'select-multiple') continue;" // FIXME: <select>
					@"if ((elem.type == 'checkbox' || elem.type == 'radio') && !elem.checked) continue;"
					// HACK: Disable presumed AJAX mode on Google Maps.
					// "output=js" seems unlikely to show up desired somewhere else,
					// so rather than a site-specific exception, we just ban all such keys.
					// It is more likely someone at Google will reuse this code than
					// someone legitimately requiring "output=js" for a successful search.
					// Unfortunately, we don't have anything to replace it with.
					@"if (elem.name == 'output' && elem.value == 'js') continue;"
					@"action += encodeURIComponent(elem.name);"
					@"action += '=';"
					@"action += encodeURIComponent(elem.value);"
					@"action += '&';"
				@"}"
				@"document.activeElement.value = old;"
				@"return action;"
			@"} else {"
				@"return ' GET';"
			@"}"
		@"} else {"
			@"return '';"
		@"}"];
	
	id <ComBelkadanKeystone_SheetRequest> sheetRequest;
	if ([formURLString isEqual:@" GET"]) {
		ComBelkadanKeystone_AlertSheetRequest *request = [[ComBelkadanKeystone_AlertSheetRequest alloc] initWithModalDelegate:self didCloseSelector:@selector(alertSheetRequestDidEnd:returnCode:unused:) contextInfo:NULL];
		
		NSBundle *keystoneBundle = [NSBundle bundleForClass:[ComBelkadanKeystone_Controller class]];
		
		request.label = NSLocalizedStringFromTableInBundle(@"Failed to create completion", @"Localizable", keystoneBundle, @"Title for completion autodiscovery failures");
		[request.alert setMessageText:NSLocalizedStringFromTableInBundle(@"Could not create a completion for this search.", @"Localizable", keystoneBundle, @"Error message for completion autodiscovery failures")];
		[request.alert setInformativeText:NSLocalizedStringFromTableInBundle(@"This form does not encode its query in a URL.", @"Localizable", keystoneBundle, @"Error message for completion autodiscovery failures")];
		
		sheetRequest = request;

	} else {
		if (!formURLString || [formURLString rangeOfString:kAutodiscoverySearch options:0].location == NSNotFound) {
			// The query doesn't actually include the active search field.
			// (This case also handles a failure in the JavaScript.)
			ComBelkadanKeystone_AlertSheetRequest *request = [[ComBelkadanKeystone_AlertSheetRequest alloc] initWithModalDelegate:self didCloseSelector:@selector(alertSheetRequestDidEnd:returnCode:unused:) contextInfo:NULL];
			
			NSBundle *keystoneBundle = [NSBundle bundleForClass:[ComBelkadanKeystone_Controller class]];
			
			request.label = NSLocalizedStringFromTableInBundle(@"Failed to create completion", @"Localizable", keystoneBundle, @"Title for completion autodiscovery failures");
			[request.alert setMessageText:NSLocalizedStringFromTableInBundle(@"Could not create a completion for this search.", @"Localizable", keystoneBundle, @"Error message for completion autodiscovery failures")];
			[request.alert setInformativeText:NSLocalizedStringFromTableInBundle(@"Keystone could not figure out what part of the URL represents the query.", @"Localizable", keystoneBundle, @"Error message for completion autodiscovery failures")];
			
			sheetRequest = request;
			
		} else {
			// We have a good query (hopefully)
			NSMutableString *completionURLString = [formURLString mutableCopy];

			// Remove final '&', do some very stupid validation
			[completionURLString deleteCharactersInRange:NSMakeRange([completionURLString length]-1, 1)];
			NSAssert([completionURLString characterAtIndex:0] != '#', @"fragment targets should have been stripped");
			NSAssert([completionURLString rangeOfString:@"?"].location != NSNotFound, @"all searches should have query parts");

			// Resolve relative URLs, then replace our query
			NSURL *url = [NSURL URLWithString:completionURLString relativeToURL:[doc currentURL]];
			NSAssert1(url, @"Malformed completion URL: %@", completionURLString);

			[completionURLString setString:[url absoluteString]];
			[completionURLString replaceOccurrencesOfString:kAutodiscoverySearch withString:ComBelkadanKeystone_kSubstitutionMarker options:0 range:NSMakeRange(0, [completionURLString length])];
			
			ComBelkadanKeystone_AddCompletionController *addSheet = [[ComBelkadanKeystone_AddCompletionController alloc] initWithName:[doc displayName] URL:completionURLString];
			addSheet.delegate = self;
			[completionURLString release];

			sheetRequest = addSheet;
		}
	}
	
	[pendingConfirmations addObject:sheetRequest];
	[sheetRequest displaySheetInWindow:[doc windowForSheet]];
	[sheetRequest release];
}

- (void)alertSheetRequestDidEnd:(ComBelkadanKeystone_AlertSheetRequest *)sheetRequest returnCode:(NSInteger)returnCode unused:(void *)unused {
	[pendingConfirmations removeObject:sheetRequest];
}

- (void)newCompletionSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode controller:(ComBelkadanKeystone_AddCompletionController *)controller {
	if (returnCode == NSOKButton) {
		[self addCompletionItem:controller.newCompletion];
	}
	[pendingConfirmations removeObject:controller];
}

- (IBAction)newCompletionForCurrentPage:(id)sender {
	NSDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];

	NSString *completionURLString = [doc URLString];
	if (!completionURLString) return;

	ComBelkadanKeystone_AddCompletionController *sheetRequest = [[ComBelkadanKeystone_AddCompletionController alloc] initWithName:[doc displayName] URL:completionURLString];
	sheetRequest.delegate = self;
	[pendingConfirmations addObject:sheetRequest];
	[sheetRequest release];
	
	[sheetRequest displaySheetInWindow:[doc windowForSheet]];
}

- (void)addCompletionItem:(ComBelkadanKeystone_QueryCompletionItem *)item {
	[sortedCompletionPossibilities addObject:item];
	[completionTable reloadData];
	[self save];
}

#pragma mark -

- (NSString *)headerTitle {
	return NSLocalizedStringFromTableInBundle(@"Keystone Shortcuts", @"Localizable", [NSBundle bundleForClass:[self class]], @"The header title in the completions list");
}

- (NSArray *)completionsForQueryString:(NSString *)query {
	return [self completionsForQueryString:query single:NO];
}

- (ComBelkadanKeystone_FakeCompletionItem *)firstCompletionForQueryString:(NSString *)query {
	return [self completionsForQueryString:query single:YES];
}

- (id)completionsForQueryString:(NSString *)query single:(BOOL)onlyOne {
	if ([query rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]].location != NSNotFound) {
		NSUInteger splitLoc = [query rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location;
		NSString *keyword;
		
		if (splitLoc == NSNotFound) keyword = query;
		else keyword = [query substringToIndex:splitLoc];
		
		NSMutableArray *results = (onlyOne ? nil : [NSMutableArray array]);
		NSUInteger max = [sortedCompletionPossibilities count];
		
		ComBelkadanKeystone_QueryCompletionItem *item;
		NSUInteger index;
		
		if ([keyword length] > 0) {		
			NSUInteger index = [sortedCompletionPossibilities indexOfObjectWithPrimarySortValue:keyword positionOnly:YES];
			
			while (index < max) {
				item = [sortedCompletionPossibilities objectAtIndex:index];
				
				if ((splitLoc == NSNotFound && [[item keyword] hasPrefix:keyword]) || [[item keyword] isEqual:keyword]) {
					if (onlyOne) {
						if ([item canBeFirstSelectedForQueryString:query]) return item;
					} else {
						[results addObject:item];
					}
				} else break;
				
				index += 1;
			}
		}
		
		index = 0;
		while (index < max) {
			item = [sortedCompletionPossibilities objectAtIndex:index];
			if ([item.keyword length] == 0) {
				if (onlyOne) {
					if ([item canBeFirstSelectedForQueryString:query]) return item;
				} else {
					[results addObject:item];
				}
			} else break;
			
			index += 1;
		}
				
		return (onlyOne ? nil : results);
	} else {
		return (onlyOne ? nil : [NSArray array]);
	}
}

- (NSArray *)completionsForKeyword:(NSString *)keyword {
	NSUInteger index = [sortedCompletionPossibilities indexOfObjectWithPrimarySortValue:keyword];
	if (index == NSNotFound) return [NSArray array];

	NSMutableArray *results = [NSMutableArray arrayWithCapacity:2];
	NSUInteger max = [sortedCompletionPossibilities count];

	do {
		ComBelkadanKeystone_QueryCompletionItem *next = [sortedCompletionPossibilities objectAtIndex:index];
		if (![keyword isEqual:next.keyword])
			break;
		[results addObject:next];
		++index;
	} while (index < max);

	return results;
}

#pragma mark -

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
	// Special case for WebKit, but we want to relaunch Safari anyway
	NSBundle *appBundle = [NSBundle bundleWithIdentifier:@"org.webkit.nightly.WebKit"];
	if (!appBundle) appBundle = [NSBundle mainBundle];
	return [appBundle bundlePath];
}

- (NSString *)permissionPromptDescriptionTextForUpdater:(SUUpdater *)updater {
	// A WebKit Sparkle branch extension
	return NSLocalizedStringFromTableInBundle(@"Should Keystone automatically check for updates?", @"Localizable", [NSBundle bundleForClass:[self class]], @"Updater messages");
}

#pragma mark -

- (IBAction)exportSettings:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"plist"]];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel beginSheetForDirectory:nil file:@"Keystone Settings" modalForWindow:[completionTable window] modalDelegate:self didEndSelector:@selector(exportSettingsPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];	
}

- (void)exportSettingsPanelDidEnd:(NSSavePanel *)savePanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused {
	if (returnCode == NSCancelButton) return;

	NSMutableDictionary *settings = [[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] mutableCopy];
	NSString *bundleVersion = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	[settings setObject:bundleVersion forKey:kKeystonePreferencesDomain];

	[settings writeToURL:[savePanel URL] atomically:YES];
	[settings release];
}

- (IBAction)importSettings:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"plist"] modalForWindow:[completionTable window] modalDelegate:self didEndSelector:@selector(importSettingsPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)importSettingsPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)unused {
	if (returnCode == NSCancelButton) return;
	[openPanel orderOut:nil];

	[self importSettingsFromURL:[openPanel URL]];
}

- (void)importSettingsFromURL:(NSURL *)url {
	NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfURL:url];
	NSString *settingsVersion = [settings objectForKey:kKeystonePreferencesDomain];
	NSArray *completions = [settings objectForKey:kPreferencesCompletionKey];

	if (!settingsVersion && !completions) {
		NSBundle *keystoneBundle = [NSBundle bundleForClass:[self class]];

		NSAlert *sorry = [[[NSAlert alloc] init] autorelease];
		[sorry setIcon:[NSImage imageNamed:kKeystoneIconName]];
		[sorry setMessageText:NSLocalizedStringFromTableInBundle(@"Could not read settings file.", @"Localizable", keystoneBundle, @"Settings import/export")];
		[sorry setInformativeText:NSLocalizedStringFromTableInBundle(@"This does not appear to be a Keystone settings file.", @"Localizable", keystoneBundle, @"Settings import/export")];

		[sorry beginSheetModalForWindow:[completionTable window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];

	} else if ([settingsVersion compare:@"2" options:NSCaseInsensitiveSearch|NSNumericSearch] != NSOrderedAscending) {
		NSBundle *keystoneBundle = [NSBundle bundleForClass:[self class]];

		NSAlert *sorry = [[[NSAlert alloc] init] autorelease];
		[sorry setIcon:[NSImage imageNamed:kKeystoneIconName]];
		[sorry setMessageText:NSLocalizedStringFromTableInBundle(@"Could not read settings file.", @"Localizable", keystoneBundle, @"Settings import/export")];
		[sorry setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"These settings are for Keystone %@, but you have %@.", @"Localizable", keystoneBundle, @"Settings import/export"), settingsVersion, [keystoneBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]]];

		[sorry beginSheetModalForWindow:[completionTable window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	} else {
		BOOL changed = NO;
		for (NSDictionary *dict in completions) {
			ComBelkadanKeystone_QueryCompletionItem *item = [[ComBelkadanKeystone_QueryCompletionItem alloc] initWithDictionary:dict];
			NSUInteger index = [sortedCompletionPossibilities indexOfObjectWithPrimarySortValue:item.keyword];
			NSUInteger count = [sortedCompletionPossibilities count];
			BOOL found = NO;
			while (index < count) {
				ComBelkadanKeystone_QueryCompletionItem *existing = [sortedCompletionPossibilities objectAtIndex:index];
				if (![existing.keyword isEqual:item.keyword]) {
					break;
				} else if ([existing.URL isEqual:item.URL]) {
					found = YES;
					break;
				}
				++index;
			}

			if (!found) {
				[sortedCompletionPossibilities addObject:item];
				changed = YES;
			}

			[item release];
		}

		if (changed) {
			[self save];
			[completionTable reloadData];
		}

		// Even though this is a secret setting right now, we should handle it.
		NSNumber *autocompletionMode = [settings objectForKey:kPreferencesAutocompletionModeKey];
		if (autocompletionMode) {
			ComBelkadanUtils_DefaultsDomain *defaults = [ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain];
			if (![autocompletionMode isEqual:[defaults objectForKey:kPreferencesAutocompletionModeKey]]) {
				[defaults setObject:autocompletionMode forKey:kPreferencesAutocompletionModeKey];
			}
		}
	}
	
	[settings release];
}

- (NSDragOperation)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)view validateDrop:(id <NSDraggingInfo>)info {
	NSPasteboard *pboard = [info draggingPasteboard];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
	NSAssert([type isEqual:NSFilenamesPboardType], @"Only our drag type should be enabled.");

	NSArray *array = [pboard propertyListForType:type];
	if ([array count] != 1) return NSDragOperationNone;

	if (![[[array objectAtIndex:0] pathExtension] isEqual:@"plist"]) return NSDragOperationNone;

	return NSDragOperationCopy;
}

- (BOOL)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)view acceptDrop:(id <NSDraggingInfo>)info {
	NSPasteboard *pboard = [info draggingPasteboard];
	NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]];
	NSAssert([type isEqual:NSFilenamesPboardType], @"Only our drag type should be enabled.");
	
	NSArray *array = [pboard propertyListForType:type];
	[self importSettingsFromURL:[NSURL fileURLWithPath:[array objectAtIndex:0]]];

	// Whether or not we succeeded in importing the file, the drag icon should
	// still not slide back.
	return YES;
}

#pragma mark -

- (NSString *)preferencesNibName {
	return @"KeystonePreferences";
}

- (NSImage *)imageForPreferenceNamed:(NSString *)name {
	return [NSImage imageNamed:kKeystoneIconName];
}

- (void)setPreferencesView:(NSView *)view {
	if (isSafari5) {
		// Resize the preference pane to fit the new aspect ratio
		NSRect frame = [view frame];
		frame.size.width = 668;
		[view setFrame:frame];
	}

	[super setPreferencesView:view];
}

- (void)moduleWasInstalled {
	[super moduleWasInstalled];
	[dropOverlay registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (BOOL)isResizable {
	return NO;
}

- (IBAction)addOrRemoveItem:(NSSegmentedControl *)sender {
	if ([sender selectedSegment] == kAddButtonPosition) {
		ComBelkadanKeystone_QueryCompletionItem *item = [[ComBelkadanKeystone_QueryCompletionItem alloc]
			initWithName:@"New Shortcut" keyword:@"(s)" shortcutURL:@""];
		[self addCompletionItem:item];
		[item release];
		
		NSInteger index = [sortedCompletionPossibilities indexOfObject:item];
		[completionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
		[completionTable editColumn:0 row:index withEvent:nil select:YES];
		
	} else {
		[sortedCompletionPossibilities removeObjectsAtIndexes:[completionTable selectedRowIndexes]];
		[completionTable reloadData];
		[self save];
	}
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [sortedCompletionPossibilities count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [[sortedCompletionPossibilities objectAtIndex:row] valueForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *columnID = [tableColumn identifier];
	ComBelkadanKeystone_QueryCompletionItem *item = [sortedCompletionPossibilities objectAtIndex:row];
	
	if (![[item valueForKey:columnID] isEqual:object]) {
		if (object == nil) object = @"";
		
		[item setValue:object forKey:columnID];
		NSUInteger newIndex = [sortedCompletionPossibilities objectDidChangeAtIndex:row];
		
		if (row != (NSInteger)newIndex) {
			NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:newIndex];
			[tableView selectRowIndexes:indexSet byExtendingSelection:NO];
			[indexSet release];
		}
		
		[self performSelector:@selector(save) withObject:nil afterDelay:0];
	}
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
	[addRemoveControl setEnabled:([proposedSelectionIndexes count] > 0) forSegment:kRemoveButtonPosition];
	return proposedSelectionIndexes;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqual:@"keyword"] && [[cell stringValue] length] == 0) {
		[cell setPlaceholderString:NSLocalizedStringFromTableInBundle(@"(Default)", @"Localizable", [NSBundle bundleForClass:[self class]], @"A default action's name")];
	}
}

@end
