#import <AppKit/NSWindow.h>

@interface CompletionWindow : NSWindow
{
}

- (BOOL)wantsScrollWheelEvent:(NSEvent *)scrollEvent;
- (double)cornerRadius;
- (BOOL)cornersAreRounded;
- (void)setCornersAreRounded:(BOOL)roundTheCorners;

@end
