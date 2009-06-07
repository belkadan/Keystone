#import "FakeCompletionItem.h"
#import <Cocoa/Cocoa.h>

extern NSString * const ComBelkadanKeystone_kDefaultActionKeyword;
extern NSString * const ComBelkadanKeystone_kSubstitutionMarker;

@interface ComBelkadanKeystone_QueryCompletionItem : ComBelkadanKeystone_FakeCompletionItem {
  NSString *name;
  NSString *keyword;
  NSString *shortcutURL;
}

- (id)initWithName:(NSString *)givenName keyword:(NSString *)givenKeyword shortcutURL:(NSString *)URLString;

@property (readwrite,copy) NSString *name;
@property (readwrite,copy) NSString *URL;
@property (readwrite,copy) NSString *keyword;
@end

