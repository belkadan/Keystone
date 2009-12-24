#import "AddCompletionController.h"
#import "KeystoneController.h"

@implementation ComBelkadanKeystone_AddCompletionController

- (id)initWithName:(NSString *)name URL:(NSString *)completionURL {
	NSString *keyword;

	NSString *host = [[NSURL URLWithString:[completionURL stringByReplacingOccurrencesOfString:ComBelkadanKeystone_kSubstitutionMarker withString:@""]] host];
	if (host) {
		// use domain name
		NSRange searchRange = NSMakeRange(0, [host length]-1); // omit trailing . for absolute addresses
		NSRange finalDotRange = [host rangeOfString:@"." options:NSBackwardsSearch|NSLiteralSearch range:searchRange];
		if (finalDotRange.location != NSNotFound) {
			searchRange.length = finalDotRange.location;
			NSRange penultimateDotRange = [host rangeOfString:@"." options:NSBackwardsSearch|NSLiteralSearch range:searchRange];
			if (penultimateDotRange.location != NSNotFound) {
				keyword = [host substringWithRange:NSMakeRange(penultimateDotRange.location+1, finalDotRange.location-penultimateDotRange.location-1)];
			} else {
				keyword = [host substringToIndex:finalDotRange.location];
			}
		} else if ([host characterAtIndex:searchRange.length] == '.') {
			keyword = [host substringToIndex:searchRange.length];
		} else {
			keyword = host;
		}

	} else {
		// use page title
		NSRange spaceRange = [name rangeOfString:@" "];
		if (spaceRange.location != NSNotFound) {
			keyword = [name substringToIndex:spaceRange.location];
		} else {
			keyword = name;
		}
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
	NSImage *icon = [[NSImage imageNamed:@"NSApplicationIcon"] copy]; // FIXME: why doesn't Safari like my icon?
	[icon setSize:NSMakeSize(16, 16)];
	return [icon autorelease];
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
@dynamic window; // just to stop warnings! we have one inherited from NSWindowController

@end
