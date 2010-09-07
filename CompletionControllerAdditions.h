#import <Cocoa/Cocoa.h>

@protocol ComBelkadanKeystone_CompletionHandler;
@class ComBelkadanKeystone_FakeCompletionItem;

enum {
	ComBelkadanKeystone_AutocompletionNone = 0,

	ComBelkadanKeystone_AutocompletionSpaces = (1 << 0),
	ComBelkadanKeystone_AutocompletionKeywords = (1 << 1),

	ComBelkadanKeystone_AutocompletionDefault = (ComBelkadanKeystone_AutocompletionSpaces | ComBelkadanKeystone_AutocompletionKeywords)
};
typedef NSUInteger ComBelkadanKeystone_AutocompletionMode;

/*!
 * The main controller for the underlying Keystone system. Keeps track of all
 * registered completion handlers.
 */
@interface ComBelkadanKeystone_URLCompletionController : NSObject
+ (void)addCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;
+ (void)removeCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler;

+ (NSArray *)completionsForQueryString:(NSString *)query headers:(BOOL)shouldInsertHeaders;
+ (ComBelkadanKeystone_FakeCompletionItem *)autocompleteForQueryString:(NSString *)query;
+ (void)setAutocompletionMode:(ComBelkadanKeystone_AutocompletionMode)newMode;
@end
