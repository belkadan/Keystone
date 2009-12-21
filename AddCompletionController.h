#import <Cocoa/Cocoa.h>
#import "QueryCompletionItem.h"

@interface ComBelkadanKeystone_AddCompletionController : NSWindowController {
	ComBelkadanKeystone_QueryCompletionItem *newCompletion;
}
- (id)initWithName:(NSString *)name URL:(NSString *)completionURL;
- (id)initWithName:(NSString *)name keyword:(NSString *)keyword URL:(NSString *)completionURL;

@property(readonly) ComBelkadanKeystone_QueryCompletionItem *newCompletion;

- (IBAction)close:(id)sender;
@end
