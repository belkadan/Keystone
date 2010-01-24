#import <AppKit/NSWindow.h>


@interface NSWindow (ComBelkadanAppUtils_EndEditingGracefully)
- (void)endEditingGracefully;
- (IBAction)clearFirstResponder:(id)sender;
@end
