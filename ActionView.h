#import <AppKit/AppKit.h>

/*!
 * This subclass of NSView sends an action when its background is clicked, like
 * an NSButton. The reason it is <em>not</em> an NSButton is because NSButtons
 * cannot have subviews. The most effective use is as a window's background.
 */
@interface ComBelkadanUtils_ActionView : NSView {
	id target;
	SEL action;
}

@property(readwrite,assign) id target;
@property(readwrite,assign) SEL action;
@end

@compatibility_alias ActionView ComBelkadanUtils_ActionView;
