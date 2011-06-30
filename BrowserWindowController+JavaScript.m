#import "SwizzleMacros.h"

#import "BrowserWindowController+JavaScript.h"

@interface ComBelkadanKeystone_BrowserWindowController_JavaScript ()
- (void)ComBelkadanKeystone_setStatusCatcher:(NSMutableString *)str;
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
		COPY_METHOD(self, toClass, ComBelkadanKeystone_setStatusCatcher:);
		COPY_AND_EXCHANGE(self, toClass, ComBelkadanKeystone_, _setStatusMessage:ellipsize:);
	}
}

#pragma mark -

- (NSString *)ComBelkadanKeystone_evaluateBeforeDate:(NSDate *)date javaScript:(NSString *)js {
	NSMutableString *status = [NSMutableString new];
	[self ComBelkadanKeystone_setStatusCatcher:status];
	[[self document] evaluateJavaScript:[NSString stringWithFormat:@"window.status = (function(){%@})()", js]];
	
	while ([status isEqual:@""] && [date timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:date];
	}

	[self ComBelkadanKeystone_setStatusCatcher:nil];
	return [status autorelease];
}

- (void)ComBelkadanKeystone_setStatusCatcher:(NSMutableString *)str {
	objc_setAssociatedObject(self, (void*)[ComBelkadanKeystone_BrowserWindowController_JavaScript class], str, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
