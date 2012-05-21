#import "ActionView.h"

/*!
 * This subclass of NSView sends an action when its background is clicked, like
 * an NSButton. The reason it is <em>not</em> an NSButton is because NSButtons
 * cannot have subviews. The most effective use is as a window's background.
 */
@implementation ActionView
@synthesize target, action;

- (void)mouseDown:(NSEvent *)event
{
	[NSApp sendAction:self.action to:self.target from:self];
}

@end
