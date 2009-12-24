#import <Cocoa/Cocoa.h>
#import "QueryCompletionItem.h"
#import "SheetRequest.h"

/*!
 * Handles the popup for adding new completions, and reports back to the main
 * controller once the user has made a choice.
 */
@interface ComBelkadanKeystone_AddCompletionController : NSWindowController <ComBelkadanKeystone_SheetRequest> {
	ComBelkadanKeystone_QueryCompletionItem *newCompletion;
}
/*! 
 * Creates a new controller for the given site name and URL, using the first word
 * of the site name as the keyword. (The actual part of the name used to generate
 * the keyword may change.)
 */
- (id)initWithName:(NSString *)name URL:(NSString *)completionURL;

/*!
 * Creates a new controller for the given site name, suggested keyword, and URL.
 * This is the designated initializer.
 */
- (id)initWithName:(NSString *)name keyword:(NSString *)keyword URL:(NSString *)completionURL;

/*! The completion being edited. */
@property(readonly) ComBelkadanKeystone_QueryCompletionItem *newCompletion;

/*! Called to close the sheet. The tag of the sender is used as the return code. */
- (IBAction)close:(id)sender;
@end
