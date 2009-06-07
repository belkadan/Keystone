#import "KeystoneController.h"
#import "CompletionControllerAdditions.h"
#import "QueryCompletionItem.h"

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

@interface ComBelkadanKeystone_Controller ()
- (BOOL)loadCompletions;
- (BOOL)loadSogudiCompletions;
- (void)loadDefaultCompletions;
@end

@interface NSDocument (ComBelkadanKeystone_IKnowYoureInThere)
@property(readonly) WebFrameView *mainWebFrameView;
@end

@interface DOMDocument (ComBelkadanKeystone_IKnowYoureInThere)
@property(readonly) DOMNode *activeElement;
@end

@implementation ComBelkadanKeystone_Controller
+ (void)load
{
  [ComBelkadanKeystone_URLCompletionController addCompletionHandler:[self sharedInstance]];

  NSImage *prefIcon = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"Preferences"]];
  [prefIcon setName:@"ComBelkadanKeystone_Preferences"];

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
    
    if (![self loadCompletions]) {
      [self loadSogudiCompletions];
    }
  }
  
  return self;
}

- (void)dealloc {
  [sortedCompletionPossibilities release];
  [super dealloc];
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

- (NSString *)attemptAutodiscovery:(id)sender {
  NSArray *textTypes = [[NSArray alloc] initWithObjects:@"text", @"search", nil];
  
  DOMDocument *currentPage = [[[[[NSDocumentController sharedDocumentController] currentDocument] mainWebFrameView] webFrame] DOMDocument];
  DOMNode *activeNode = currentPage.activeElement;
  NSString *nodeName = activeNode.localName;
  
  DOMHTMLFormElement *form = nil;
  if ([nodeName isEqual:@"input"]) {
    NSString *type = ((DOMHTMLInputElement *)activeNode).type;
    if ([textTypes containsObject:type]) {
      [activeNode setValue:@"__________"];
      form = ((DOMHTMLInputElement *)activeNode).form;
    }
    
  } else if ([nodeName isEqual:@"textarea"]) {
    [activeNode setValue:@"__________"];
    form = ((DOMHTMLTextAreaElement *)activeNode).form;
  }
  
  if (!form) {
    NSBeep();
    [textTypes release];
    return nil;
    
  } else {
    NSMutableString *search = [form.action mutableCopy];
    [search appendString:@"?"];
    
    DOMHTMLCollection *formElements = form.elements;
    DOMNode *next;
    BOOL first = YES;
    for (unsigned i = 1; i < formElements.length; i += 1) {
      next = [formElements item:i];
      
      if (![next isKindOfClass:[DOMHTMLInputElement class]] ||
          ((DOMHTMLInputElement *)next).checked ||
          [textTypes containsObject:((DOMHTMLInputElement *)next).type]) {
        if (!first) [search appendString:@"&"];
        [search appendString:[[next name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [search appendString:@"="];
        [search appendString:[[next value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        first = NO;
      }
    }
    
    [textTypes release];
    return [search autorelease];
  }
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
    [sortedCompletionPossibilities addObject:item];
    [completionTable reloadData];
    
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
    
    if (newIndex != row) {
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
