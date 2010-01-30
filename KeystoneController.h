#import <Cocoa/Cocoa.h>
#import "SortedArray.h"
#import "QueryCompletionItem.h"
#import "CompletionHandler.h"
#import "NSPreferences.h"

@class SUUpdater;

/*!
 * The main controller for Keystone query completions. In addition to being a
 * completion handler, also manages the menu items and preference panes.
 */
@interface ComBelkadanKeystone_Controller : NSPreferencesModule <ComBelkadanKeystone_CompletionHandler> {
	ComBelkadanUtils_SortedArray *sortedCompletionPossibilities;
	
	IBOutlet NSTableView *completionTable;
	IBOutlet NSSegmentedControl *addRemoveControl;

	NSMutableArray *pendingConfirmations;
	
	SUUpdater *updater;
}
//+ (id)sharedInstance; // inherited from NSPreferencesModule
- (void)save;
- (IBAction)addOrRemoveItem:(NSSegmentedControl *)sender;
- (void)addCompletionItem:(ComBelkadanKeystone_QueryCompletionItem *)item;

- (id)completionsForQueryString:(NSString *)query single:(BOOL)onlyOne;

- (IBAction)attemptAutodiscovery:(id)sender;
- (IBAction)newCompletionForCurrentPage:(id)sender;
- (void)newCompletionSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode controller:(id)controller;

@property(readonly) SUUpdater *updater;
@end
