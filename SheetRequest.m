#import "SheetRequest.h"

@interface ComBelkadanKeystone_AlertSheetRequest ()
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode unused:(void *)unused;
@end

typedef void (*DidCloseIMP)(id, SEL, ComBelkadanKeystone_AlertSheetRequest *, NSInteger, void *);

@implementation ComBelkadanKeystone_AlertSheetRequest

- (id)initWithModalDelegate:(id)givenDelegate didCloseSelector:(SEL)givenCloseSelector contextInfo:(void *)givenContextInfo {
	self = [super init];
	if (self) {
		delegate = givenDelegate;
		didCloseSelector = givenCloseSelector;
		contextInfo = givenContextInfo;
	
		alert = [[NSAlert alloc] init];
	}
	return self;
}

- (void)dealloc {
	[label release];
	[alert release];
	[super dealloc];
}

#pragma mark -

- (id)icon {
	NSImage *icon = [[NSImage imageNamed:@"NSApplicationIcon"] copy]; // FIXME: why doesn't Safari like my icon?
	[icon setSize:NSMakeSize(16, 16)];
	return [icon autorelease];
}

- (void)displaySheetInWindow:(NSWindow *)window {
	if (window == nil) window = [NSApp mainWindow];
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:unused:) contextInfo:NULL];
}

- (void)displaySheet {
	[self displaySheetInWindow:nil];
}

- (void)alertDidEnd:(NSAlert *)givenAlert returnCode:(NSInteger)returnCode unused:(void *)unused {
	DidCloseIMP didCloseMethod = (DidCloseIMP)[delegate methodForSelector:didCloseSelector];
	if (didCloseMethod) {
		didCloseMethod(delegate, didCloseSelector, self, returnCode, contextInfo);
	}
}

- (NSWindow *)window {
	return [alert window];
}

@synthesize label, alert;
@end
