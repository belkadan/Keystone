#import <Foundation/Foundation.h>

@class ComBelkadanKeystone_FakeCompletionItem;

/*! A source of new completions. Pretty simple to implement. */
@protocol ComBelkadanKeystone_CompletionHandler

/*! The title to be displayed as a header in the completion list, or nil for no header. */
- (NSString *)headerTitle;

/*! Returns all possible completions for a given query (an array of FakeCompletionItems) */
- (NSArray *)completionsForQueryString:(NSString *)query;

/*!
 * Returns the first possible completion for a given query.
 * A good implementation will return an item which canBeFirstSelectedForQueryString:
 * for this query.
 */
- (ComBelkadanKeystone_FakeCompletionItem *)firstCompletionForQueryString:(NSString *)query;
@end
