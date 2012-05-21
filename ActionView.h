#import <AppKit/AppKit.h>

@interface ComBelkadanUtils_ActionView : NSView {
	id target;
	SEL action;
}

@property(readwrite,assign) id target;
@property(readwrite,assign) SEL action;
@end

@compatibility_alias ActionView ComBelkadanUtils_ActionView;
