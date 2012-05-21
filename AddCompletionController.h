#import <Cocoa/Cocoa.h>
#import "QueryCompletionItem.h"
#import "SheetRequest.h"


@protocol ComBelkadanKeystone_AddCompletionDelegate
- (NSArray *)completionsForKeyword:(NSString *)keyword;
@end


/*!
 * Handles the popup for adding new completions, and reports back to the main
 * controller once the user has made a choice.
 */
@interface ComBelkadanKeystone_AddCompletionController : NSWindowController <ComBelkadanKeystone_SheetRequest> {
	id <ComBelkadanKeystone_AddCompletionDelegate> delegate;
	ComBelkadanKeystone_QueryCompletionItem *newCompletion;

	NSPanel *tooltipFloatWindow;
	IBOutlet NSTextView *warningView;
}

- (id)initWithName:(NSString *)name URL:(NSString *)completionURL;
- (id)initWithName:(NSString *)name keyword:(NSString *)keyword URL:(NSString *)completionURL;

@property(readonly) ComBelkadanKeystone_QueryCompletionItem *newCompletion;

@property(readwrite,nonatomic,assign) id <ComBelkadanKeystone_AddCompletionDelegate> delegate;

- (IBAction)showWarning:(id)sender;
- (IBAction)close:(id)sender;
@end
