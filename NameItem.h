#import <Cocoa/Cocoa.h>
#import "FakeCompletionItem.h"

@protocol ComBelkadanUtils_OrderedMutableArray;


@interface ComBelkadanKeystoneNames_NameItem : ComBelkadanKeystone_FakeCompletionItem {
	NSString *key;
	NSString *name;
	NSString *userID;
}

+ (void)addItemsForName:(NSString *)name userID:(NSString *)userID toArray:(NSArray <ComBelkadanUtils_OrderedMutableArray> *)items;
- (id)initWithName:(NSString *)givenName keyword:(NSString *)givenKeyword userID:(NSString *)givenID;

@property(readonly,copy) NSString *key;
@property(readonly,copy) NSString *name;
@property(readonly,copy) NSString *userID;

- (BOOL)matchesNameComponents:(NSArray *)components;

@end
