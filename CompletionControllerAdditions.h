#import <Cocoa/Cocoa.h>
#import "CompletionControllers.h"

@protocol ComBelkadanKeystone_CompletionHandler;

/*!
 * The main controller for the underlying Keystone system. Keeps track of all
 * registered completion handlers.
 */
@interface ComBelkadanKeystone_URLCompletionController : URLCompletionController
+ (void)addCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;
+ (void)removeCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;
@end
