#import <Cocoa/Cocoa.h>
#import "SortedArray.h"
#import "QueryCompletionItem.h"
#import "CompletionHandler.h"
#import "NSPreferences.h"

@interface ComBelkadanKeystone_Controller : NSPreferencesModule <ComBelkadanKeystone_CompletionHandler> {
	ComBelkadanUtils_SortedArray *sortedCompletionPossibilities;
	
	IBOutlet NSTableView *completionTable;
	IBOutlet NSSegmentedControl *addRemoveControl;

	NSMutableArray *pendingConfirmations;
}
//+ (id)sharedInstance; // inherited from NSPreferencesModule
- (void)save;
- (IBAction)addOrRemoveItem:(NSSegmentedControl *)sender;
- (void)addCompletionItem:(ComBelkadanKeystone_QueryCompletionItem *)item;

- (id)completionsForQueryString:(NSString *)query single:(BOOL)onlyOne;

- (void)newCompletionSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode controller:(id)controller;
@end
