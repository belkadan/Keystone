#import <AppKit/NSWindow.h>

@interface CompletionWindow : NSWindow
{
}

- (BOOL)wantsScrollWheelEvent:(NSEvent *)scrollEvent;
- (CGFloat)cornerRadius;
- (BOOL)cornersAreRounded;
- (void)setCornersAreRounded:(BOOL)roundTheCorners;

@end
