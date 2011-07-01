#import "CompletionServer.h"

#import "FakeCompletionItem.h"
#import "CompletionHandler.h"

#import "SortedArray.h"

@interface ComBelkadanKeystone_CompletionServer ()
+ (void)appendCompletionsForQueryString:(NSString *)query toArray:(NSMutableArray *)results headers:(BOOL)shouldInsertHeaders;
@end


static NSArray <ComBelkadanUtils_OrderedMutableArray> *additionalCompletions = nil;
static ComBelkadanKeystone_AutocompletionMode autocompletionMode = ComBelkadanKeystone_AutocompletionDefault;

@implementation ComBelkadanKeystone_CompletionServer
+ (void)initialize {
	if (self != [ComBelkadanKeystone_CompletionServer class])
		return;
	
	additionalCompletions = [[SortedArray alloc] initWithPrimarySortKey:@"headerTitle"];
}

+ (void)addCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler {
	[additionalCompletions addObject:handler];
}

+ (void)removeCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler {
	[additionalCompletions removeObject:handler];
}

+ (NSArray *)completionsForQueryString:(NSString *)query headers:(BOOL)shouldInsertHeaders {
	NSMutableArray *results = [NSMutableArray array];
	[self appendCompletionsForQueryString:query toArray:results headers:shouldInsertHeaders];
	return results;
}

+ (void)appendCompletionsForQueryString:(NSString *)query toArray:(NSMutableArray *)results headers:(BOOL)shouldInsertHeaders {
	for (id <ComBelkadanKeystone_CompletionHandler> nextHandler in additionalCompletions) {
		NSArray *customCompletions = [nextHandler completionsForQueryString:query];
		
		if ([customCompletions count] > 0) {
			if ([results count] > 0) {
				[results addObject:[ComBelkadanKeystone_FakeCompletionItem separatorItem]];
			}
			
			if (shouldInsertHeaders) {
				NSString *title = [nextHandler headerTitle];
				if (title) {
					ComBelkadanKeystone_FakeCompletionItem *headerItem = [[ComBelkadanKeystone_SimpleCompletionItem alloc] initWithName:title URLString:nil];
					[results addObject:headerItem];
					[headerItem release];
				}
			}
			
			[results addObjectsFromArray:customCompletions];
		}
	}
}

+ (ComBelkadanKeystone_FakeCompletionItem *)autocompleteForQueryString:(NSString *)query {
	BOOL needsExactMatch = YES;
	if (autocompletionMode & ComBelkadanKeystone_AutocompletionSpaces) {
		if ([query rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound) {
			needsExactMatch = NO;
		}
	}
	
	if (autocompletionMode & ComBelkadanKeystone_AutocompletionKeywords) {
		for (id <ComBelkadanKeystone_CompletionHandler> nextHandler in additionalCompletions) {
			ComBelkadanKeystone_FakeCompletionItem *supplied = [nextHandler firstCompletionForQueryString:query];
			if (supplied) {
				if (!needsExactMatch || [supplied isExactMatchForQueryString:query]) {
					return supplied;
				}
			}
		}
	}
	
	return nil;	
}

+ (void)setAutocompletionMode:(ComBelkadanKeystone_AutocompletionMode)newMode {
	autocompletionMode = newMode;
}

@end


