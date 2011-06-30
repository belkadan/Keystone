//
//  DefaultsDomain.h
//  Keystone
//

#import <Foundation/Foundation.h>

@interface ComBelkadanUtils_DefaultsDomain : NSMutableDictionary {
	NSString *domain;
	NSMutableDictionary *values;
}

+ (ComBelkadanUtils_DefaultsDomain *)domainForName:(NSString *)domainName;

- (void)refresh;

@property (readonly,nonatomic) NSString *domain;
@end

@compatibility_alias DefaultsDomain ComBelkadanUtils_DefaultsDomain;
