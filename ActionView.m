#import "ActionView.h"

@implementation ActionView
@synthesize target, action;

- (void)mouseDown:(NSEvent *)event
{
	[NSApp sendAction:self.action to:self.target from:self];
}

@end
