#import <Foundation/NSObject.h>

/* generated with class-dump */

@protocol NSTableViewDataSource;
@protocol NSTableViewDelegate;
@class CompletionWindow, CompletionListTableView;

struct CompletionListItem {
    void **_field1;
    int _field2;
    _Bool _field3;
};

struct STimer_CompletionController {
    void **_vptr;
    NSUInteger m_ID;
    _Bool m_isRepeating;
    struct CompletionController *m_object;
    struct {
		void *__pfn;
		NSInteger __delta;
	} m_function;
} /* STimer_7d4eea56 */;

@interface CompletionControllerObjCAdapter : NSObject
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
<NSTableViewDataSource, NSTableViewDelegate>
#endif
{
    struct CompletionController {
        void **_vptr;
        int _possiblyRefCount;
        CompletionControllerObjCAdapter *_adapter;
        CompletionWindow *_window;
        CompletionListTableView *_table;
        NSWindow *_owningWindow;
        const struct {
			NSUInteger m_size;
			struct {
				struct CompletionListItem **m_buffer;
				NSUInteger m_capacity;
			} m_buffer;
		} _items;
        NSString *_str;
        struct STimer_CompletionController _timer1;
        struct STimer_CompletionController _timer2;
        struct STimer_CompletionController _timer3;
        double _real;
        NSUInteger _int;
        _Bool _flag1;
        _Bool _flag2;
        _Bool _flag3;
        _Bool _flag4;
        _Bool _flag5;
        _Bool _flag6;
        _Bool _flag7;
    } *_completionController;
}
- (id)initWithCompletionController:(struct CompletionController *)cppCompletionController;

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsSeparator:(NSInteger)row;
- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsChecked:(NSInteger)row;
- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowSpansAllColumns:(NSInteger)row;
- (void)completionListTableView:(CompletionListTableView *)tableView mouseUpInRow:(NSInteger)row;

- (void)completionListDidShow;
- (void)completionListDidHide;
@end


#if 0
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
#endif