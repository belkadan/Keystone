#import "AddCompletionController.h"
#import "KeystoneController.h"
#import "NSWindow+EndEditingGracefully.h"
#import "ActionView.h"

@interface ComBelkadanKeystone_AddCompletionController ()
- (void)setUpWarning;
@end

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
	[tooltipFloatWindow release];
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

- (NSArray *)existingCompletions {
	if (delegate) {
		return [delegate completionsForKeyword:newCompletion.keyword ?: @""];
	} else {
		return [NSArray array];
	}
}

+ (NSSet *)keyPathsForValuesAffectingExistingCompletions {
	return [NSSet setWithObject:@"newCompletion.keyword"];
}

- (NSString *)existingCompletionWarning {
	NSArray *existingCompletions = [self existingCompletions];

	if (!newCompletion.keyword) {
		switch ([existingCompletions count]) {
		case 0:
			return nil;
		case 1: {
			ComBelkadanKeystone_QueryCompletionItem *completion = [existingCompletions objectAtIndex:0];
			return [NSString stringWithFormat:@"There is already a default search shortcut: '%@'", completion.name];		
		}
		case 2: {
			ComBelkadanKeystone_QueryCompletionItem *first = [existingCompletions objectAtIndex:0];
			ComBelkadanKeystone_QueryCompletionItem *second = [existingCompletions objectAtIndex:1];
			return [NSString stringWithFormat:@"There are already default search shortcuts: '%@' and '%@'.", first.name, second.name];		
		}
		default:
			return [NSString stringWithFormat:@"There are already default search shortcuts: '%@'", [[existingCompletions valueForKey:@"name"] componentsJoinedByString:@"', '"]];
		}		
	} else {
		switch ([existingCompletions count]) {
		case 0:
			return nil;
		case 1: {
			ComBelkadanKeystone_QueryCompletionItem *completion = [existingCompletions objectAtIndex:0];
			return [NSString stringWithFormat:@"'%@' is already using this keyword.", completion.name];		
		}
		case 2: {
			ComBelkadanKeystone_QueryCompletionItem *first = [existingCompletions objectAtIndex:0];
			ComBelkadanKeystone_QueryCompletionItem *second = [existingCompletions objectAtIndex:1];
			return [NSString stringWithFormat:@"This keyword is already in use by '%@' and '%@'.", first.name, second.name];		
		}
		default:
			return [NSString stringWithFormat:@"This keyword is already in use. ('%@')", [[existingCompletions valueForKey:@"name"] componentsJoinedByString:@"', '"]];
		}		
	}
}

+ (NSSet *)keyPathsForValuesAffectingExistingCompletionWarning {
	return [NSSet setWithObject:@"existingCompletions"];
}

- (void)controlTextDidChange:(NSNotification *)obj {
	[tooltipFloatWindow orderOut:nil];
}

- (IBAction)showWarning:(NSView *)sender
{
	static const NSSize kMinSize = { .width = 220, .height = 18 };

	if (!tooltipFloatWindow) {
		[self setUpWarning];
		NSAssert(tooltipFloatWindow, @"The fake tooltip panel should exist now.");
	}
	
	NSPoint topLeftCorner = NSMakePoint(0, ([sender isFlipped] ? 0 : NSMaxY([sender bounds])));
	topLeftCorner = [[sender window] convertBaseToScreen:[sender convertPointToBase:topLeftCorner]];

	[warningView setString:@""];
	[warningView setFrameSize:kMinSize];
	[warningView setString:[self existingCompletionWarning]];
	[warningView sizeToFit];

	NSRect frame;
	frame.size = [[warningView superview] convertSizeToBase:[warningView frame].size];
	frame.origin.x = topLeftCorner.x;
	frame.origin.y = topLeftCorner.y - frame.size.height;
	[tooltipFloatWindow setFrame:frame display:YES];

	[tooltipFloatWindow makeKeyAndOrderFront:sender];
}

- (void)setUpWarning
{
	NSScrollView *scrollView = [warningView enclosingScrollView];
	NSRect initialFrame = {
		.origin = NSZeroPoint,
		.size = [scrollView bounds].size
	};
	
	tooltipFloatWindow = [[NSPanel alloc] initWithContentRect:initialFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[tooltipFloatWindow setFloatingPanel:YES];
	[tooltipFloatWindow setLevel:NSFloatingWindowLevel+5];
	[tooltipFloatWindow setHasShadow:YES];	
	[[tooltipFloatWindow contentView] addSubview:scrollView];
	
	ActionView *actionView = [[ActionView alloc] initWithFrame:initialFrame];
	[actionView setTarget:tooltipFloatWindow];
	[actionView setAction:@selector(orderOut:)];
	[actionView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
	[[tooltipFloatWindow contentView] addSubview:actionView positioned:NSWindowAbove relativeTo:nil];
	[actionView release];
	
	[warningView setTextContainerInset:NSMakeSize(0, 2)];
}

#pragma mark -

- (IBAction)close:(id)sender {
	if (!newCompletion.keyword) newCompletion.keyword = @"";
	if (!newCompletion.name) newCompletion.name = @"";

	[tooltipFloatWindow orderOut:self];
	
	NSWindow *window = [self window];
	[window endEditingGracefully];
	if ([window isSheet]) {
		[NSApp endSheet:window returnCode:[sender tag]];
	}
	[window orderOut:self];
}

@synthesize newCompletion, delegate;
@dynamic window; // just to stop warnings! we have one inherited from NSWindowController

@end
