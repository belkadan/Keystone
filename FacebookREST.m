#import "FacebookREST.h"
#import "SortedArray.h"
#import "NameItem.h"

static NSString * const kFacebookLoadURL = @"http://belkadan.com/facebook/keystone-names/get.php?id=";

BOOL fetchFriendItems (NSArray <ComBelkadanUtils_OrderedMutableArray> *items, NSString *userID, NSError **error) {
	NSURL *requestURL = [[NSURL alloc] initWithString:[kFacebookLoadURL stringByAppendingString:[userID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
	[requestURL release];
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:error];
	[request release];

	if (!data) {
		return NO;
	}
	
	NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSScanner *responseScanner = [[NSScanner alloc] initWithString:contents];
	
	NSString *friendID, *name;
	while ([responseScanner scanUpToString:@" " intoString:&friendID]) {
		[responseScanner scanString:@" " intoString:NULL];
		[responseScanner scanUpToString:@"\n" intoString:&name];
		
		[ComBelkadanKeystoneNames_NameItem addItemsForName:name userID:friendID toArray:items];
	}
	
	[responseScanner release];
	[contents release];
	
	return YES;
}
