#import <Cocoa/Cocoa.h>
#import "CompletionHandler.h"
#import "NSPreferences.h"

@class SortedArray;

@interface ComBelkadanKeystoneNames_Controller : NSPreferencesModule <ComBelkadanKeystone_CompletionHandler> {
	SortedArray *nameItems;
}
//+ (id)sharedInstance; // inherited from NSPreferencesModule
- (id)completionsForQueryString:(NSString *)query single:(BOOL)onlyOne;
@end

extern NSString * const kComBelkadanKeystoneNames_preferencesDomain;
