#import "DefaultsDomain.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#ifndef MAC_OS_X_VERSION_10_6
@interface NSObject ()
- (id)forwardingTargetForSelector:(SEL)selector;
@end
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
	if (!inTransaction) {
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:values forName:self.domain];
	}
}

- (void)beginTransaction {
	inTransaction = YES;
}

- (void)endTransaction {
	inTransaction = NO;
	[self save];
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

- (id)forwardingTargetForSelector:(SEL)cmd {
	if ([[NSDictionary class] instancesRespondToSelector:cmd]) {
		return values;
	} else {
		return [super forwardingTargetForSelector:cmd];
	}
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	SEL cmd = [invocation selector];
	if ([[NSMutableDictionary class] instancesRespondToSelector:cmd]) {
		[invocation invokeWithTarget:values];
		[self save];
		
	} else {
		[super forwardInvocation:invocation];
	}
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)cmd {
	NSMethodSignature *result = [super methodSignatureForSelector:cmd];
	if (!result) result = [values methodSignatureForSelector:cmd];
	return result;
}
@end
