#import "KeystoneNamesController.h"
#import "CompletionControllerAdditions.h"
#import "NameItem.h"
#import "SortedArray.h"

#import <libkern/OSAtomic.h>

NSString * const kComBelkadanKeystoneNames_preferencesDomain = @"com.belkadan.KeystoneNames";
static NSUInteger maxResultCount = 5;

@implementation ComBelkadanKeystoneNames_Controller
+ (void)load
{
	[ComBelkadanKeystone_URLCompletionController addCompletionHandler:[self sharedInstance]];
}

- (id)init {
	if ((self = [super init])) {
		NSArray *descriptors = [[NSArray alloc] initWithObjects:
			[[NSSortDescriptor alloc] initWithKey:@"key" ascending:YES selector:@selector(caseInsensitiveCompare:)],
			[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES],
			[[NSSortDescriptor alloc] initWithKey:@"userID" ascending:YES],
			nil];
		nameItems = [[ComBelkadanUtils_SortedArray alloc] initWithSortDescriptors:descriptors];
		[descriptors makeObjectsPerformSelector:@selector(release)];
		[descriptors release];
		
		[ComBelkadanKeystoneNames_NameItem addItemsForName:@"Jordy Rose" userID:@"742505532" toArray:nameItems];
		[ComBelkadanKeystoneNames_NameItem addItemsForName:@"Lily Lin" userID:@"1061250113" toArray:nameItems];
		[ComBelkadanKeystoneNames_NameItem addItemsForName:@"Lindy Jiang" userID:@"514034422" toArray:nameItems];
	}
	
	return self;
}

- (void)dealloc {
	[nameItems release];
	[super dealloc];
}

#pragma mark -

- (NSString *)headerTitle {
	return NSLocalizedStringFromTableInBundle(@"Keystone Names", @"Localizable", [NSBundle bundleForClass:[self class]], @"The header title in the completions list");
}

- (NSArray *)completionsForQueryString:(NSString *)query {
	return [self completionsForQueryString:query single:NO];
}

- (ComBelkadanKeystone_FakeCompletionItem *)firstCompletionForQueryString:(NSString *)query {
	return [self completionsForQueryString:query single:YES];
}

- (id)completionsForQueryString:(NSString *)query single:(BOOL)onlyOne {
	NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
	if ([query rangeOfCharacterFromSet:[whitespace invertedSet]].location != NSNotFound) {
		NSArray *nameComponents = [query componentsSeparatedByCharactersInSet:whitespace];
		NSUInteger nextComponentIndex = 0;
		NSString *keyword;
		
		do {
			keyword = [nameComponents objectAtIndex:nextComponentIndex];
			nextComponentIndex += 1;
		} while ([keyword length] == 0);
		
		NSMutableDictionary *results = (onlyOne ? nil : [[NSMutableDictionary alloc] init]);
		NSUInteger max = [nameItems count];
		
		ComBelkadanKeystoneNames_NameItem *item;
		NSUInteger completionIndex = [nameItems indexOfObjectWithPrimarySortValue:keyword positionOnly:YES];
			
		while (completionIndex < max && [results count] < maxResultCount) {
			item = [nameItems objectAtIndex:completionIndex];
			
			if (![results objectForKey:[item userID]]) {
				if ([item matchesNameComponents:nameComponents]) {
					if (onlyOne) return item;
					else [results setObject:item forKey:[item userID]];
					
				} else if ([item.key rangeOfString:keyword options:NSCaseInsensitiveSearch].location != 0) {
					break;
				}
			}
			
			completionIndex += 1;
		}
		
		NSArray *resultArray = [[results allValues] sortedArrayUsingDescriptors:nameItems.sortDescriptors];
		[results release];
		return (onlyOne ? nil : resultArray);
	} else {
		return (onlyOne ? nil : [NSArray array]);
	}
}

@end
