#import "NameItem.h"
#import "KeystoneNamesController.h"
#import "SortedArray.h"

static NSString *templateURL = @"http://facebook.com/profile.php?id=%%";

@implementation ComBelkadanKeystoneNames_NameItem
/*+ (void)initialize {
	templateURL = (NSString *)CFPreferencesCopyAppValue((CFStringRef) @"templateURL", (CFStringRef) kComBelkadanKeystoneNames_preferencesDomain);
}*/

+ (void)addItemsForName:(NSString *)name userID:(NSString *)userID toArray:(NSArray <ComBelkadanUtils_OrderedMutableArray> *)items {
	ComBelkadanKeystoneNames_NameItem *nextItem;
	
	for (NSString *nextWord in [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
		nextItem = [[ComBelkadanKeystoneNames_NameItem alloc] initWithName:name keyword:nextWord userID:userID];
		[items addObject:nextItem];
		[nextItem release];
	}
}

- (id)initWithName:(NSString *)givenName keyword:(NSString *)givenKeyword userID:(NSString *)givenID {
	if ((self = [super init])) {
		name = [givenName copy];
		key = [givenKeyword copy];
		userID = [givenID copy];
	}
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
	return [self initWithName:[dict objectForKey:@"name"] keyword:[dict objectForKey:@"keyword"] userID:[dict objectForKey:@"userID"]];
}

- (void)dealloc {
	[name release];
	[key release];
	[userID release];
	[super dealloc];
}

#pragma mark -

- (NSString *)URL {
	return [templateURL stringByReplacingOccurrencesOfString:@"%%" withString:userID];
}

- (BOOL)matchesNameComponents:(NSArray *)components {
	NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
	NSUInteger max = [name length];

	for (NSString *next in components) {
		if ([next length] > 0) {
			NSRange range = [name rangeOfString:next options:NSCaseInsensitiveSearch];
			
			if (range.location == NSNotFound) {
				return NO;
			} else if (range.location > 0) {
				while (![whitespace characterIsMember:[name characterAtIndex:(range.location - 1)]]) {
					range.location += 1;
					range.length = max - range.location;
					range = [name rangeOfString:next options:NSCaseInsensitiveSearch range:range];
					
					if (range.location == NSNotFound) return NO;
				}
			}
		}
	}
	
	return YES;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p: %@ (%@)>", NSStringFromClass([self class]), self, self.key, self.name];
}

@synthesize name, key, userID;
@end
