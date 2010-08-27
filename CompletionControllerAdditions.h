#import <Cocoa/Cocoa.h>

@protocol ComBelkadanKeystone_CompletionHandler;
@class ComBelkadanKeystone_FakeCompletionItem;

/*!
 * The main controller for the underlying Keystone system. Keeps track of all
 * registered completion handlers.
 */
@interface ComBelkadanKeystone_URLCompletionController : NSObject
+ (void)addCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;
+ (void)removeCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;

+ (NSArray *)completionsForQueryString:(NSString *)query headers:(BOOL)shouldInsertHeaders;
+ (ComBelkadanKeystone_FakeCompletionItem *)firstItemForQueryString:(NSString *)queryString;

// FIXME: remove this
+ (NSArray *)completionHandlers;
@end

@interface NSString (ComBelkadanKeystone_QueryAdditions)
- (BOOL)ComBelkadanKeystone_queryWantsCompletion;
@end
