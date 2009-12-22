#import "KeystoneController.h"
#import "CompletionControllerAdditions.h"
#import "CompletionAdapterAdditions.h"
#import "AddCompletionController.h"

#import <WebKit/WebKit.h>
#import <libkern/OSAtomic.h>

static NSString * const kKeystonePreferencesDomain = @"com.belkadan.Keystone";
static NSString * const kPreferencesCompletionKey = @"SortedCompletions";
static NSString * const kDefaultPreferencesFile = @"defaults"; // extension must be .plist

static NSString * const kSogudiCompletionsFile = @"SogudiShortcuts.plist";
static NSString * const kSogudiDefaultActionKeyword = @"default";
static NSString * const kSogudiSubstitutionMarker = @"@@@";

enum {
	kAddButtonPosition = 0,
	kRemoveButtonPosition
};

@interface ComBelkadanKeystone_Controller () <NSUserInterfaceValidations>
- (BOOL)loadCompletions;
- (BOOL)loadSogudiCompletions;
- (void)loadDefaultCompletions;

- (void)setUpMenuItems;

- (void)autodiscoveryLoadDidFinish:(NSNotification *)note;
- (IBAction)attemptAutodiscovery:(id)sender;
@end

@interface NSObject (ComBelkadanKeystone_StopWarnings)
- (void)addBookmark:(id)bookmark;
@end

@interface NSDocument (ComBelkadanKeystone_IKnowYoureInThere)
@property(readonly) WebView *currentWebView;
@end

@interface DOMDocument (ComBelkadanKeystone_IKnowYoureInThere)
@property(readonly) DOMNode *activeElement;
@end

@interface WebView (ComBelkadanKeystone_ActuallyInSafariSubclass)
- (void)setSheetRequest:(id)sheetRequest;
@end

@implementation ComBelkadanKeystone_Controller
+ (void)load
{
	[ComBelkadanKeystone_URLCompletionController addCompletionHandler:[self sharedInstance]];

	static NSImage *prefIcon = nil;
	if (!prefIcon) {
		prefIcon = [NSImage imageNamed:@"ComBelkadanKeystone_Preferences"];
		if (!prefIcon) {
			prefIcon = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"Preferences"]];
			[prefIcon setName:@"ComBelkadanKeystone_Preferences"];
		}
	}

	[[NSClassFromString(@"WBPreferences") sharedPreferences] addPreferenceNamed:NSLocalizedStringFromTableInBundle(@"Keystone", @"Localizable", [NSBundle bundleForClass:[self class]], @"The preferences pane title") owner:[self sharedInstance]];
}

- (id)init {
	if ((self = [super init])) {
		NSArray *descriptors = [[NSArray alloc] initWithObjects:
			[[NSSortDescriptor alloc] initWithKey:@"keyword" ascending:YES],
			[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES],
			[[NSSortDescriptor alloc] initWithKey:@"URL" ascending:YES],
			nil];
		sortedCompletionPossibilities = [[ComBelkadanUtils_SortedArray alloc] initWithSortDescriptors:descriptors];
		[descriptors makeObjectsPerformSelector:@selector(release)];
		[descriptors release];

		pendingConfirmations = [[NSMutableArray alloc] init];
		
		if (![self loadCompletions]) {
			[self loadSogudiCompletions];
		}

		[self setUpMenuItems];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[sortedCompletionPossibilities release];
	[pendingConfirmations release];
	[super dealloc];
}

- (void)setUpMenuItems {
  NSMenu *mainMenu = [NSApp mainMenu];
	NSMenu *bookmarksMenu = nil;

	// first try by name
	NSString *bookmarksMenuName = NSLocalizedStringWithDefaultValue(@"Bookmarks (menu)", @"Localizable", [NSBundle mainBundle], @"Bookmarks", @"Safari Windows name for Bookmarks menu");
	bookmarksMenu = [[mainMenu itemWithTitle:bookmarksMenuName] submenu];
	
	if (!bookmarksMenu) {
		// search for the menu item with the action addBookmark:
		for (NSMenuItem *topMenuItem in [mainMenu itemArray]) {
			NSMenu *nextMenu = [topMenuItem submenu];
			if ([nextMenu indexOfItemWithTarget:nil andAction:@selector(addBookmark:)] != NSNotFound) {
				bookmarksMenu = nextMenu;
				break;
			}
		}
	}

	if (bookmarksMenu) {
		NSString *autodiscoverTitle = NSLocalizedStringFromTableInBundle(@"Add Keystone Completion...", @"Localizable", [NSBundle bundleForClass:[self class]], @"Autodiscovery menu item title");
		NSMenuItem *autodiscoverItem = [[NSMenuItem alloc] initWithTitle:autodiscoverTitle action:@selector(attemptAutodiscovery:) keyEquivalent:@""];
		[autodiscoverItem setTarget:self];

		NSInteger separatorIndex = [bookmarksMenu indexOfItem:[NSMenuItem separatorItem]];
		if (separatorIndex == -1) {
			[bookmarksMenu addItem:autodiscoverItem];
		} else {
			[bookmarksMenu insertItem:autodiscoverItem atIndex:separatorIndex];
		}

		[autodiscoverItem release];
	}
}

#pragma mark -

- (BOOL)loadCompletions {
	NSArray *completionsInPlistForm = (NSArray *)CFPreferencesCopyAppValue((CFStringRef) kPreferencesCompletionKey, (CFStringRef) kKeystonePreferencesDomain);
	if (!completionsInPlistForm) return NO;
	
	for (NSDictionary *completionDict in completionsInPlistForm) {
		ComBelkadanKeystone_QueryCompletionItem *nextItem = [[ComBelkadanKeystone_QueryCompletionItem alloc] initWithDictionary:completionDict];
		if (nextItem) {
			[sortedCompletionPossibilities addObject:nextItem];
			[nextItem release];
		}
	}
	
	CFRelease(completionsInPlistForm);
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
	CFPreferencesSetMultiple((CFDictionaryRef)defaults, NULL, (CFStringRef)kKeystonePreferencesDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	[defaults release];
	
	[self loadCompletions];
}

- (void)save {
	if ([completionTable editedRow] != -1) {
		[self performSelector:@selector(save) withObject:nil afterDelay:200];
	} else {
		NSArray *completionsInPlistForm = [sortedCompletionPossibilities valueForKey:@"dictionaryRepresentation"];
		CFPreferencesSetAppValue((CFStringRef) kPreferencesCompletionKey, (CFArrayRef)completionsInPlistForm, (CFStringRef) kKeystonePreferencesDomain);
		CFPreferencesAppSynchronize((CFStringRef) kKeystonePreferencesDomain);
	}
}

#pragma mark -

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item {
	if ([item action] == @selector(attemptAutodiscovery:)) {
		WebView *webView = [[[NSDocumentController sharedDocumentController] currentDocument] currentWebView];
		DOMDocument *currentPage = [webView mainFrameDocument];
		DOMNode *activeNode = currentPage.activeElement;
		NSString *nodeName = activeNode.localName;

		DOMHTMLFormElement *form = nil;
		if ([nodeName isEqual:@"input"]) {
			NSString *type = ((DOMHTMLInputElement *)activeNode).type;
			if ([[NSArray arrayWithObjects:@"text", @"search", nil] containsObject:type]) {
				form = ((DOMHTMLInputElement *)activeNode).form;
			}
			
		} else if ([nodeName isEqual:@"textarea"]) {
			form = ((DOMHTMLTextAreaElement *)activeNode).form;
		}

		return form != nil;
	} else {
		return NO;
	}
}

- (IBAction)attemptAutodiscovery:(id)sender {
	NSString *autodiscoveryString = @"---Keystone---"; // TODO: put somewhere else
	
	WebView *webView = [[[NSDocumentController sharedDocumentController] currentDocument] currentWebView];
	DOMDocument *currentPage = [webView mainFrameDocument];
	DOMNode *activeNode = currentPage.activeElement;
	NSString *nodeName = activeNode.localName;
	
	DOMHTMLFormElement *form = nil;
	if ([nodeName isEqual:@"input"]) {
		// text input already validated
		[activeNode setValue:autodiscoveryString];
		form = ((DOMHTMLInputElement *)activeNode).form;
		
	} else if ([nodeName isEqual:@"textarea"]) {
		[activeNode setValue:autodiscoveryString];
		form = ((DOMHTMLTextAreaElement *)activeNode).form;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autodiscoveryLoadDidFinish:) name:WebViewProgressFinishedNotification object:webView];
	[form submit]; // TODO: avoid polluting history
}

- (void)autodiscoveryLoadDidFinish:(NSNotification *)note {
	// TODO: verify that this is the search the user wanted to do
	WebView *webView = [note object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:WebViewProgressFinishedNotification object:webView];

	NSString *completionURLString = [webView mainFrameURL];
	completionURLString = [completionURLString stringByReplacingOccurrencesOfString:@"---Keystone---" withString:ComBelkadanKeystone_kSubstitutionMarker options:NSCaseInsensitiveSearch range:NSMakeRange(0, [completionURLString length])];

	// TODO: complain if we couldn't make a search URL

	ComBelkadanKeystone_AddCompletionController *confirmController =
		[[ComBelkadanKeystone_AddCompletionController alloc] initWithName:[webView mainFrameTitle] URL:completionURLString];

	[pendingConfirmations addObject:confirmController];
	[confirmController release];

	if ([webView respondsToSelector:@selector(setSheetRequest:)]) {
		[webView setSheetRequest:confirmController];
	} else {
		[confirmController displaySheetInWindow:[webView window]];
	}
}

- (void)newCompletionSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode controller:(ComBelkadanKeystone_AddCompletionController *)controller {
	if (returnCode == NSOKButton) {
		[self addCompletionItem:controller.newCompletion];
	}
	[pendingConfirmations removeObject:controller];
}

- (void)addCompletionItem:(ComBelkadanKeystone_QueryCompletionItem *)item {
	[sortedCompletionPossibilities addObject:item];
	[completionTable reloadData];
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
		NSUInteger splitLoc = [query rangeOfString:@" "].location;
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

- (NSString *)preferencesNibName {
	return @"KeystonePreferences";
}

- (NSImage *)imageForPreferenceNamed:(NSString *)name {
	return [NSImage imageNamed:@"ComBelkadanKeystone_Preferences"];
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
