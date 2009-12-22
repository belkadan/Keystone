#import <Cocoa/Cocoa.h>
// In Safari, this is an actual class, SheetRequest

@protocol ComBelkadanKeystone_SheetRequest
- (NSImage *)icon;
- (NSString *)label;
- (NSWindow *)window;
- (void)displaySheetInWindow:(NSWindow *)window;
- (void)displaySheet;
@end