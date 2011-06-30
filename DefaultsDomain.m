//
//  DefaultsDomain.m
//  Keystone
//

#import "DefaultsDomain.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

static NSMutableDictionary *domains = nil;

@interface ComBelkadanUtils_DefaultsDomain ()
- (id)initWithDomainName:(NSString *)domainName;
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
#if !__has_feature(objc_arc)
		[domain release];
#endif
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

#if !__has_feature(objc_arc)
- (void)dealloc {
	[domain release];
	[values release];
	[super dealloc];
}
#endif

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

// TODO: setValue:forKeyPath:

#pragma mark -

- (void)forwardInvocation:(NSInvocation *)invocation {
	SEL cmd = [invocation selector];
	if ([[NSDictionary class] instancesRespondToSelector:cmd]) {
		[invocation invokeWithTarget:values];

	} else if ([[NSMutableDictionary class] instancesRespondToSelector:cmd]) {
		[invocation invokeWithTarget:values];
		[self save];
		
	} else {
		[self doesNotRecognizeSelector:cmd];
	}
}
@end
