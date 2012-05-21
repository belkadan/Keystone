#import <Cocoa/Cocoa.h>

@class ComBelkadanUtils_DropOverlayView;

@protocol ComBelkadanUtils_DropOverlayViewDelegate <NSObject>

- (BOOL)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)view acceptDrop:(id <NSDraggingInfo>)info;

@optional
- (NSDragOperation)dropOverlayView:(ComBelkadanUtils_DropOverlayView *)view validateDrop:(id <NSDraggingInfo>)info;

@end


@interface ComBelkadanUtils_DropOverlayView : NSView {
	id <ComBelkadanUtils_DropOverlayViewDelegate> delegate;
}

@property(readwrite,assign) IBOutlet id <ComBelkadanUtils_DropOverlayViewDelegate> delegate;

@end
