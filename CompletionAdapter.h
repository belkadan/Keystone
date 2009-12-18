#import <Cocoa/Cocoa.h>

/* generated with class-dump */
/* Safari 4.0.3+ */
struct CompletionController;
@class OldCompletionController;

@interface CompletionControllerObjCAdapter : NSObject /* <NSTableViewDataSource, NSTableViewDelegate> */
{
	struct CompletionController *_completionController;
	OldCompletionController *_completionControllerObjC;
}
- (id)initWithCompletionController:(struct CompletionController *)cppCompletionController oldCompletionController:(OldCompletionController *)objcCompletionController;
- (void)performCompletion;

- (BOOL)completionListTableView:(NSTableView *)tableView rowIsSeparator:(NSInteger)row;
- (BOOL)completionListTableView:(NSTableView *)tableView rowIsChecked:(NSInteger)row;
- (void)completionListTableView:(NSTableView *)tableView mouseUpInRow:(NSInteger)row;
@end
