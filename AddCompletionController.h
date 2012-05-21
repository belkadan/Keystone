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
/*! 
 * Creates a new controller for the given site name and URL, using a reasonable
 * keyword extrapolated from the given arguments.
 */
- (id)initWithName:(NSString *)name URL:(NSString *)completionURL;

/*!
 * Creates a new controller for the given site name, suggested keyword, and URL.
 * This is the designated initializer.
 */
- (id)initWithName:(NSString *)name keyword:(NSString *)keyword URL:(NSString *)completionURL;

/*! The completion being edited. */
@property(readonly) ComBelkadanKeystone_QueryCompletionItem *newCompletion;

@property(readwrite,nonatomic,assign) id <ComBelkadanKeystone_AddCompletionDelegate> delegate;

/*! Called to close the sheet. The tag of the sender is used as the return code. */
- (IBAction)close:(id)sender;

- (IBAction)showWarning:(id)sender;
@end
