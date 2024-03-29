#import "QueryCompletionItem.h"

NSString * const ComBelkadanKeystone_kDefaultActionKeyword = @"<default>";
NSString * const ComBelkadanKeystone_kSubstitutionMarker = @"%%";

struct QueryReplacement {
	NSString *original;
	NSString *replacement;
};
// special characters which need to be replaced in URLs
struct QueryReplacement replacements[] = {
	{ @"%", @"%25" },
	{ @"+", @"%2B" },
	{ @"&", @"%26" },
	{ @" ", @"%20" },
	{ @"\"", @"%22" },
	{ nil, nil }
};

// The "everything-but-whitespace" set
static NSCharacterSet *nonWhitespaceSet = nil;

@implementation ComBelkadanKeystone_QueryCompletionItem
+ (void)initialize	{
	if (!nonWhitespaceSet) nonWhitespaceSet = [[[NSCharacterSet whitespaceCharacterSet] invertedSet] retain];
}

- (id)initWithName:(NSString *)givenName keyword:(NSString *)givenKeyword shortcutURL:(NSString *)URLString {
	if ((self = [super init])) {
		name = [givenName copy];
		keyword = [givenKeyword copy];
		shortcutURL = [URLString copy];
	}
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
	return [self initWithName:[dict objectForKey:@"name"] keyword:[dict objectForKey:@"keyword"] shortcutURL:[dict objectForKey:@"shortcutURL"]];
}

- (NSDictionary *)dictionaryRepresentation {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		name, @"name",
		keyword, @"keyword",
		shortcutURL, @"shortcutURL",
		nil];
}

- (void)dealloc {
	[name release];
	[keyword release];
	[shortcutURL release];
	[super dealloc];
}

#pragma mark -

- (BOOL)canBeFirstSelectedForQueryString:(NSString *)query {
	return [keyword length] > 0 || [query rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound;
}

- (BOOL)isExactMatchForQueryString:(NSString *)query {
	NSUInteger keywordLength = [keyword length];
	if (keywordLength == 0)
		return NO;
	
	if (![query hasPrefix:keyword])
		return NO;

	// FIXME: cache this?
	if ([query length] == keywordLength)
		return [shortcutURL rangeOfString:ComBelkadanKeystone_kSubstitutionMarker].location == NSNotFound;

	if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[query characterAtIndex:keywordLength]])
		return YES;

	return NO;
}

- (NSString *)nameForQueryString:(NSString *)query {
	NSUInteger keywordLength = [keyword length];
	if (keywordLength == 0 || [query hasPrefix:keyword] && [query length] > keywordLength) {
		query = [[query substringFromIndex:keywordLength] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		return [NSString stringWithFormat:@"%@: %@", name, query];
	} else {
		return name;
	}
}

- (NSString *)urlStringForQueryString:(NSString *)query {
	// Copy the param string
	NSUInteger keywordLength = [keyword length];
	NSMutableString *params = [query mutableCopy];
	
	// delete the keyword
	if ([params hasPrefix:keyword]) {
		[params deleteCharactersInRange:NSMakeRange(0, keywordLength)];
	} else if (keywordLength > 0) {
		[params setString:@""];
	}
	
	// trim whitespace from the left
	NSUInteger whitespaceSplit = [params rangeOfCharacterFromSet:nonWhitespaceSet].location;
	if (whitespaceSplit != NSNotFound) {
		[params deleteCharactersInRange:NSMakeRange(0, whitespaceSplit)];
	}

	// trim whitespace from the right
	NSRange lastCharRange = [params rangeOfCharacterFromSet:nonWhitespaceSet options:NSBackwardsSearch];
	if (lastCharRange.location != NSNotFound && NSMaxRange(lastCharRange) < [params length]) {
		whitespaceSplit = NSMaxRange(lastCharRange);
		[params deleteCharactersInRange:NSMakeRange(whitespaceSplit, [params length] - whitespaceSplit)];
	}
	
	// percent-escape percents and other special characters
	struct QueryReplacement *nextReplacement = &replacements[0];
	while (nextReplacement->original != nil) {
		[params replaceOccurrencesOfString:nextReplacement->original withString:nextReplacement->replacement options:NSLiteralSearch range:NSMakeRange(0, [params length])];
		++nextReplacement;
	}

	// Substitute into the shortcut URL
	NSString *result = [shortcutURL stringByReplacingOccurrencesOfString:ComBelkadanKeystone_kSubstitutionMarker withString:params];
	[params release];
	return result;
}

- (NSString *)reflectedStringForQueryString:(NSString *)query withSelectionFrom:(NSUInteger *)selectionStart {
	NSUInteger queryLength = [query length];

	*selectionStart = queryLength;
	if (queryLength < [keyword length] && [keyword hasPrefix:query]) {
		return keyword;
	} else {
		return query;
	}
}

@synthesize name, keyword;
@synthesize URL=shortcutURL;
@end

