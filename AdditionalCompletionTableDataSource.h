#import <Cocoa/Cocoa.h>

@class CompletionWindow;
@class CompletionListTableView;

@class ComBelkadanKeystone_FakeCompletionItem;

@protocol ComBelkadanKeystone_AdditionalCompletionsDelegate
- (void)ComBelkadanKeystone_completionItemSelected:(ComBelkadanKeystone_FakeCompletionItem *)item forQuery:(NSString *)query;
- (void)ComBelkadanKeystone_completionItemChosen:(ComBelkadanKeystone_FakeCompletionItem *)item forQuery:(NSString *)query;
@end


@interface ComBelkadanKeystone_AdditionalCompletionTableDataSource : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
	CompletionWindow *window;
	IBOutlet CompletionListTableView *table;
	id <ComBelkadanKeystone_AdditionalCompletionsDelegate> delegate;

	NSArray *currentCompletions;
	NSString *query;
	BOOL wasCanceled;
}

+ (ComBelkadanKeystone_AdditionalCompletionTableDataSource *)sharedInstance;

@property(readwrite,copy) NSArray *currentCompletions;
@property(readwrite,copy) NSString *query;

@property(readonly) NSWindow *window;
@property(readwrite,assign) id <ComBelkadanKeystone_AdditionalCompletionsDelegate> delegate;

- (BOOL)isActive;
- (BOOL)isVisible;
- (BOOL)wasCanceled;
- (void)clearCanceled;

- (void)showWindowForField:(NSView *)field;
- (void)updateQuery:(NSString *)query;
@end
