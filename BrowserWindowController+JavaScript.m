#import "SwizzleMacros.h"

#import "BrowserWindowController+JavaScript.h"

@interface ComBelkadanKeystone_BrowserWindowController_JavaScript ()
- (void)ComBelkadanKeystone__setStatusMessage:(NSString *)status ellipsize:(BOOL)shouldEllipsize;
@end

@interface NSWindowController (ComBelkadanKeystone_BrowserWindowController_JavaScript)
- (void)_setStatusMessage:(NSString *)status ellipsize:(BOOL)shouldEllipsize;
@end

@interface NSDocument (ComBelkadanKeystone_IKnowYoureInThere)
- (void)evaluateJavaScript:(NSString *)js;
@end


static NSMapTable *allCatchers = nil;

static void setStatusCatcher(id obj, NSMutableString *catcher) {
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
	extern void objc_setAssociatedObject(id object, void *key, id value, objc_AssociationPolicy policy) WEAK_IMPORT_ATTRIBUTE;
	if (objc_setAssociatedObject) {
		objc_setAssociatedObject(obj, &allCatchers, catcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		return;
	}

#endif
	if (!allCatchers) {
		allCatchers = [[NSMapTable alloc] initWithKeyOptions:(NSPointerFunctionsObjectPointerPersonality|NSPointerFunctionsOpaqueMemory) valueOptions:NSPointerFunctionsObjectPersonality capacity:2];
	}
	[allCatchers setObject:catcher forKey:obj];
}

static void clearStatusCatcher(id obj) {
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
	extern void objc_setAssociatedObject(id object, void *key, id value, objc_AssociationPolicy policy) WEAK_IMPORT_ATTRIBUTE;
	if (objc_setAssociatedObject) {
		objc_setAssociatedObject(obj, &allCatchers, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		return;
	}
	
#endif
	if (!allCatchers) {
		return;
	}
	[allCatchers removeObjectForKey:obj];
}


static NSMutableString *getStatusCatcher(id obj) {
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
	extern id objc_getAssociatedObject(id object, void *key) WEAK_IMPORT_ATTRIBUTE;
	if (objc_getAssociatedObject) {
		return objc_getAssociatedObject(obj, &allCatchers);
	}
#endif

	if (!allCatchers) {
		return nil;
	}
	return [allCatchers objectForKey:obj];
}


@implementation ComBelkadanKeystone_BrowserWindowController_JavaScript
+ (void)initialize {
	if (self == [ComBelkadanKeystone_BrowserWindowController_JavaScript class]) {
		Class toClass = NSClassFromString(@"BrowserWindowController");
		if (!toClass) toClass = NSClassFromString(@"BrowserWindowControllerMac");

		COPY_METHOD(self, toClass, ComBelkadanKeystone_evaluateBeforeDate:javaScript:);
		COPY_AND_EXCHANGE(self, toClass, ComBelkadanKeystone_, _setStatusMessage:ellipsize:);
	}
}

#pragma mark -

- (NSString *)ComBelkadanKeystone_evaluateBeforeDate:(NSDate *)date javaScript:(NSString *)js {
	if (getStatusCatcher(self) != nil) {
		// No nested JavaScript
		return nil;
	}
	
	NSMutableString *status = [NSMutableString new];
	setStatusCatcher(self, status);

	id document = [self document];
	[document evaluateJavaScript:[NSString stringWithFormat:@"window.status = (function(){%@})()", js]];
	
	while ([status isEqual:@""] && [date timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:date];
	}

	[document evaluateJavaScript:@"window.status = ''"];

	clearStatusCatcher(self);
	return [status autorelease];
}

- (void)ComBelkadanKeystone__setStatusMessage:(NSString *)status ellipsize:(BOOL)shouldEllipsize {
	NSMutableString *statusCatcher = getStatusCatcher(self);
	if (status && statusCatcher) {
		[statusCatcher setString:status];
		[self ComBelkadanKeystone__setStatusMessage:@"" ellipsize:shouldEllipsize];
	} else {
		[self ComBelkadanKeystone__setStatusMessage:status ellipsize:shouldEllipsize];
	}
}
@end
