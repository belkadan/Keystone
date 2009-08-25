#import <Cocoa/Cocoa.h>

@protocol ComBelkadanKeystone_CompletionHandler;

/*!
 * The main controller for the underlying Keystone system. Keeps track of all
 * registered completion handlers.
 */
@interface ComBelkadanKeystone_URLCompletionController : NSObject
+ (void)addCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;
+ (void)removeCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;
@end
