#import "AddCompletionController.h"
#import "KeystoneController.h"

@implementation ComBelkadanKeystone_AddCompletionController

- (id)initWithName:(NSString *)name URL:(NSString *)completionURL {
	NSRange spaceRange = [name rangeOfString:@" "];
	NSString *keyword;
	if (spaceRange.location != NSNotFound) {
		keyword = [name substringToIndex:spaceRange.location];
	} else {
		keyword = name;
	}
	
	return [self initWithName:name keyword:[keyword lowercaseString] URL:completionURL];
}

- (id)initWithName:(NSString *)name keyword:(NSString *)keyword URL:(NSString *)completionURL {
	self = [super initWithWindowNibName:@"AddCompletion"];
	if (self) {
		newCompletion = [[ComBelkadanKeystone_QueryCompletionItem alloc] initWithName:name keyword:keyword shortcutURL:completionURL];
	}
	return self;
}

- (void)dealloc {
	[newCompletion release];
	[super dealloc];
}

#pragma mark -

- (id)icon {
	return [NSImage imageNamed:NSImageNameMobileMe]; // FIXME: Keystone icon?
}

- (id)label {
	return [[self window] title];
}

- (void)displaySheetInWindow:(NSWindow *)window {
	if (window == nil) window = [NSApp mainWindow];
	[NSApp beginSheet:[self window] modalForWindow:window modalDelegate:[ComBelkadanKeystone_Controller sharedInstance] didEndSelector:@selector(newCompletionSheetDidEnd:returnCode:controller:) contextInfo:(void *)self];
}

- (void)displaySheet {
	[self displaySheetInWindow:nil];
}

#pragma mark -

- (IBAction)close:(id)sender {
	NSWindow *window = [self window];
	if ([window isSheet]) {
		[NSApp endSheet:window returnCode:[sender tag]];
	}
	[window orderOut:self];
}

@synthesize newCompletion;

@end
