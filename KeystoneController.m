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
static NSString * const kPreferencesAutocompletionModeKey = @"AutocompleteMode";
static NSString * const kDefaultPreferencesFile = @"defaults"; // extension must be .plist

static NSString * const kAutodiscoverySearch = @"---Keystone---";

static NSString * const kSogudiCompletionsFile = @"SogudiShortcuts.plist";
static NSString * const kSogudiDefaultActionKeyword = @"default";
static NSString * const kSogudiSubstitutionMarker = @"@@@";

static const int kLatestSafariSystem = 6;
static const int kLatestTestedVersionOfSafari = 534;

#define kSafariVersionNumber5 533
static BOOL isSafari5 = NO;

enum {
	kAddButtonPosition = 0,
	kRemoveButtonPosition
};

@interface ComBelkadanKeystone_Controller () <NSUserInterfaceValidations>
+ (void)alertUntested;

- (BOOL)loadCompletions;
- (BOOL)loadSogudiCompletions;
- (void)loadDefaultCompletions;

- (void)alertSheetRequestDidEnd:(ComBelkadanKeystone_AlertSheetRequest *)sheetRequest returnCode:(NSInteger)returnCode unused:(void *)unused;
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


@implementation ComBelkadanKeystone_Controller
@synthesize updater;

+ (void)load
{
	static NSImage *prefIcon = nil;
	if (!prefIcon) {
		prefIcon = [NSImage imageNamed:@"ComBelkadanKeystone_Preferences"];
		if (!prefIcon) {
			prefIcon = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"keystone"]];
			[prefIcon setName:@"ComBelkadanKeystone_Preferences"];
		}
	}

	[[NSClassFromString(@"WBPreferences") sharedPreferences] addPreferenceNamed:NSLocalizedStringFromTableInBundle(@"Keystone", @"Localizable", [NSBundle bundleForClass:[self class]], @"The preferences pane title") owner:[self sharedInstance]];

	int safariMajorVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] intValue];
	isSafari5 = (safariMajorVersion % 1000) >= kSafariVersionNumber5;

	if ((safariMajorVersion % 1000) <= kLatestTestedVersionOfSafari && (safariMajorVersion / 1000) <= kLatestSafariSystem) {
		
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
		
	} else {
		[self alertUntested];
	}
}

- (id)init {
	if ((self = [super init])) {
		NSArray *descriptors = [[NSArray alloc] initWithObjects:
			[[[NSSortDescriptor alloc] initWithKey:@"keyword" ascending:YES] autorelease],
			[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease],
			[[[NSSortDescriptor alloc] initWithKey:@"URL" ascending:YES] autorelease],
			nil];
		sortedCompletionPossibilities = [[ComBelkadanUtils_SortedArray alloc] initWithSortDescriptors:descriptors];
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

+ (void)alertUntested {
	NSBundle *keystoneBundle = [NSBundle bundleForClass:[ComBelkadanKeystone_Controller class]];
	BOOL isSuppressed = NO;

	NSString *currentVersion = [keystoneBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	NSString *suppressedVersion = [[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] objectForKey:kPreferencesCompletionKey];
	if (suppressedVersion) {
		isSuppressed = [suppressedVersion isEqual:currentVersion];
	}

	if (!isSuppressed) {
		NSAlert *alert = [[NSAlert alloc] init];
		
		[alert setIcon:[NSImage imageNamed:@"ComBelkadanKeystone_Preferences"]];
		[alert setMessageText:NSLocalizedStringFromTableInBundle(@"Keystone is not yet supported in this version of Safari.", @"Localizable", keystoneBundle, @"Unsupported alert")];
		[alert setInformativeText:NSLocalizedStringFromTableInBundle(@"Check the Keystone preference pane for updates.", @"Localizable", keystoneBundle, @"Unsupported alert")];
		
		if ([alert respondsToSelector:@selector(setShowsSuppressionButton:)]) {
			[alert setShowsSuppressionButton:YES];
			[[alert suppressionButton] setTitle:NSLocalizedStringFromTableInBundle(@"Do not show this message again for this version", @"Localizable", keystoneBundle, @"Unsupported alert")];
		}
		
		[alert runModal];
		if ([[alert suppressionButton] state] == NSOnState) {
			[[ComBelkadanUtils_DefaultsDomain domainForName:kKeystonePreferencesDomain] setObject:currentVersion forKey:kPreferencesUntestedAlertSuppressionKey];
		}
		[alert release];
	}
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

		NSString *valid = [windowController ComBelkadanKeystone_evaluateBeforeDate:[NSDate dateWithTimeIntervalSinceNow:4] javaScript:
			@"var ComBelkadanKeystone_status = false;"
			@"if (document.activeElement && document.activeElement.form) {"
				@"if (document.activeElement.nodeName == 'TEXTAREA') {"
					@"ComBelkadanKeystone_status = true;"
				@"} else if (document.activeElement.nodeName == 'INPUT') {"
					@"if (document.activeElement.type == 'text' || document.activeElement.type == 'search') {"
						@"ComBelkadanKeystone_status = true;"
					@"}"
				@"}"
			@"}"
			@"return ComBelkadanKeystone_status ? 'YES' : 'NO'"];

		return [valid boolValue];

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
				@"action += encodeURIComponent(elem.name);"
				@"action += '=';"
				@"action += encodeURIComponent(elem.value);"
				@"action += '&';"
			@"}"
			@"document.activeElement.value = old;"
			@"return action;"
		@"} else {"
			@"return ' GET';"
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

			// Remove final '&' and possible initial fragid
			[completionURLString deleteCharactersInRange:NSMakeRange([completionURLString length]-1, 1)];
			if ([completionURLString characterAtIndex:0] == '#') {
				NSUInteger qIndex = [completionURLString rangeOfString:@"?"].location;
				NSAssert(qIndex != NSNotFound, @"all searches should have query parts");
				[completionURLString deleteCharactersInRange:NSMakeRange(0, qIndex)];				
			}

			// Resolve relative URLs, then replace our query
			NSURL *url = [NSURL URLWithString:completionURLString relativeToURL:[doc currentURL]];
			NSAssert1(url, @"Malformed completion URL: %@", completionURLString);

			[completionURLString setString:[url absoluteString]];
			[completionURLString replaceOccurrencesOfString:kAutodiscoverySearch withString:ComBelkadanKeystone_kSubstitutionMarker options:0 range:NSMakeRange(0, [completionURLString length])];
			
			sheetRequest = [[ComBelkadanKeystone_AddCompletionController alloc] initWithName:[doc displayName] URL:completionURLString];
			[completionURLString release];
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

	id <ComBelkadanKeystone_SheetRequest> sheetRequest = [[ComBelkadanKeystone_AddCompletionController alloc] initWithName:[doc displayName] URL:completionURLString];
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

- (NSString *)preferencesNibName {
	return @"KeystonePreferences";
}

- (NSImage *)imageForPreferenceNamed:(NSString *)name {
	return [NSImage imageNamed:@"ComBelkadanKeystone_Preferences"];
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
