#import "FakeCompletionItem.h"
#import <libkern/OSAtomic.h>

@implementation ComBelkadanKeystone_FakeCompletionItem
+ (ComBelkadanKeystone_FakeCompletionItem *)separatorItem {
	static ComBelkadanKeystone_FakeCompletionItem *separator = nil;
	if (separator == nil) {
		// The Mike Ash / Chris Hanson thread-safe singleton pattern
		ComBelkadanKeystone_FakeCompletionItem *newSeparator = [[ComBelkadanKeystone_FakeCompletionItem alloc] init];
		if (OSAtomicCompareAndSwapPtrBarrier(nil, newSeparator, (void **)&separator)) {
			CFRetain(newSeparator); // make un-collectable
		}
		[newSeparator release];
	}
	
	return separator;
}

- (BOOL)isHeader {
	return self.URL == nil;
}

- (BOOL)isSeparator {
	return self.name == nil;
}

- (BOOL)canBeFirstSelectedForQueryString:(NSString *)query {
	return !self.isHeader && !self.isSeparator && [query rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound;
}

- (BOOL)isExactMatchForQueryString:(NSString *)query {
	NSString *name = self.name;
	return name && [name compare:query options:(self.caseInsensitive ? NSCaseInsensitiveSearch : 0)] == NSOrderedSame;
}

- (BOOL)caseInsensitive {
	return YES;
}

- (NSString *)reflectedStringForQueryString:(NSString *)query withSelectionFrom:(NSInteger *)selectionStart {	
	*selectionStart = [query length];

	NSString *name = self.name;
	if (name && [name rangeOfString:query options:(self.caseInsensitive ? NSCaseInsensitiveSearch : 0)].location == 0) {
		return name;
	} else {
		return query;
	}
}

- (NSString *)name { return nil; }
- (NSString *)URL { return nil; }

- (NSString *)nameForQueryString:(NSString *)query { return self.name; }
- (NSString *)urlStringForQueryString:(NSString *)query { return self.URL; }
- (NSString *)previewURLStringForQueryString:(NSString *)query { return [self urlStringForQueryString:query]; }

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p: %@ (%@)>", NSStringFromClass([self class]), self, self.name, self.URL];
}

@end

@implementation ComBelkadanKeystone_SimpleCompletionItem

- (id)initWithName:(NSString *)givenName URLString:(NSString *)URLString {
	if ((self = [super init])) {
		name = [givenName copy];
		URL = [URLString copy];
	}
	
	return self;
}

- (void)dealloc {
	[name release];
	[URL release];
	[super dealloc];
}

@synthesize name, URL;
@end

