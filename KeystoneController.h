#import <Cocoa/Cocoa.h>
#import "SortedArray.h"
#import "CompletionHandler.h"
#import "NSPreferences.h"

@interface ComBelkadanKeystone_Controller : NSPreferencesModule <ComBelkadanKeystone_CompletionHandler> {
	ComBelkadanUtils_SortedArray *sortedCompletionPossibilities;
	
	IBOutlet NSTableView *completionTable;
	IBOutlet NSSegmentedControl *addRemoveControl;
}
//+ (id)sharedInstance; // inherited from NSPreferencesModule
- (void)save;
- (IBAction)addOrRemoveItem:(NSSegmentedControl *)sender;

- (id)completionsForQueryString:(NSString *)query single:(BOOL)onlyOne;
@end
