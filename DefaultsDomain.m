//
//  DefaultsDomain.m
//  Keystone
//

#import "DefaultsDomain.h"

static NSMutableDictionary *domains = nil;

@interface ComBelkadanUtils_DefaultsDomain ()
- (id) initWithDomainName:(NSString *)domainName;
@end

@implementation ComBelkadanUtils_DefaultsDomain
@synthesize domain;

+ (void)initialize {
	if (self == [ComBelkadanUtils_DefaultsDomain class]) {
		domains = [[NSMutableDictionary alloc] init];
	}
}

+ (ComBelkadanUtils_DefaultsDomain *)domainForName:(NSString *)domainName {
	ComBelkadanUtils_DefaultsDomain *domain = [domains objectForKey:domainName];
	if (!domain) {
		domain = [[self alloc] initWithDomainName:domainName];
		[domains setObject:domain forKey:domainName];
		[domain release];
	}
	return domain;
}

- (id)initWithDomainName:(NSString *)domainName {
	self = [super init];
	if (self) {
		domain = [domainName copy];
		values = [[NSMutableDictionary alloc] init];
		[self refresh];
	}
	
	return self;
}

- (void)dealloc {
	[domain release];
	[values release];
	[super dealloc];
}

- (void)refresh {
	[values setDictionary:[[NSUserDefaults standardUserDefaults] persistentDomainForName:self.domain]];
}

- (void)save {
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:values forName:self.domain];
}

#pragma mark -

- (id)objectForKey:(id)key {
	return [values objectForKey:key];
}

- (void)removeObjectForKey:(id)key {
	[values	removeObjectForKey:key];
	[self save];
}

- (void)setObject:(id)obj forKey:(id)key {
	[values setObject:obj forKey:key];
	[self save];
}

- (NSUInteger)count {
	return [values count];
}

- (NSEnumerator *)keyEnumerator {
	return [values keyEnumerator];
}

#pragma mark -

- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([[NSDictionary class] instancesRespondToSelector:[invocation selector]]) {
		[invocation invokeWithTarget:values];

	} else if ([[NSMutableDictionary class] instancesRespondToSelector:[invocation selector]]) {
		[invocation invokeWithTarget:values];
		[self save];
	}
}
@end
