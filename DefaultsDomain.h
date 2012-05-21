#import <Foundation/Foundation.h>

@interface ComBelkadanUtils_DefaultsDomain : NSMutableDictionary {
	NSString *domain;
	NSMutableDictionary *values;
	BOOL inTransaction;
}

+ (ComBelkadanUtils_DefaultsDomain *)domainForName:(NSString *)domainName;

- (void)refresh;

@property (readonly,copy,nonatomic) NSString *domain;

- (void)beginTransaction;
- (void)endTransaction;
@end

@compatibility_alias DefaultsDomain ComBelkadanUtils_DefaultsDomain;
