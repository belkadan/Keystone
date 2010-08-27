#import <Cocoa/Cocoa.h>

@class CompletionWindow;
@class CompletionListTableView;

@class ComBelkadanKeystone_FakeCompletionItem;

@protocol ComBelkadanKeystone_AdditionalCompletionsDelegate
- (void)ComBelkadanKeystone_completionItemSelected:(ComBelkadanKeystone_FakeCompletionItem *)item;
- (void)ComBelkadanKeystone_completionItemChosen:(ComBelkadanKeystone_FakeCompletionItem *)item;
@end


@interface ComBelkadanKeystone_AdditionalCompletionTableDataSource : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
	CompletionWindow *window;
	IBOutlet CompletionListTableView *table;
	id <ComBelkadanKeystone_AdditionalCompletionsDelegate> delegate;
}

+ (ComBelkadanKeystone_AdditionalCompletionTableDataSource *)sharedInstance;

@property(readonly) NSWindow *window;
@property(readwrite,assign) id <ComBelkadanKeystone_AdditionalCompletionsDelegate> delegate;

- (BOOL)isActive;
- (BOOL)isVisible;

- (void)showWindowForField:(NSView *)field;
- (void)updateQuery:(NSString *)query;
@end
