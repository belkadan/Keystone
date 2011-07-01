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
	if (objc_getAssociatedObject(self, (void*)[ComBelkadanKeystone_BrowserWindowController_JavaScript class])) {
		// No nested JavaScript
		return nil;
	}
	
	NSMutableString *status = [NSMutableString new];
	objc_setAssociatedObject(self, (void*)[ComBelkadanKeystone_BrowserWindowController_JavaScript class], status, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	id document = [self document];
	[document evaluateJavaScript:[NSString stringWithFormat:@"window.status = (function(){%@})()", js]];
	
	while ([status isEqual:@""] && [date timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:date];
	}

	[document evaluateJavaScript:@"window.status = ''"];

	objc_setAssociatedObject(self, (void*)[ComBelkadanKeystone_BrowserWindowController_JavaScript class], nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return [status autorelease];
}

- (void)ComBelkadanKeystone__setStatusMessage:(NSString *)status ellipsize:(BOOL)shouldEllipsize {
	NSMutableString *statusCatcher = objc_getAssociatedObject(self, (void*)[ComBelkadanKeystone_BrowserWindowController_JavaScript class]);
	if (statusCatcher) {
		[statusCatcher setString:status];
		[self ComBelkadanKeystone__setStatusMessage:@"" ellipsize:shouldEllipsize];
	} else {
		[self ComBelkadanKeystone__setStatusMessage:status ellipsize:shouldEllipsize];
	}
}
@end
