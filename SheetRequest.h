#import <Cocoa/Cocoa.h>

@protocol ComBelkadanKeystone_SheetRequest <NSObject>
- (NSImage *)icon;
- (NSString *)label;
- (NSWindow *)window;
- (void)displaySheetInWindow:(NSWindow *)window;
- (void)displaySheet;
@end

@interface ComBelkadanKeystone_AlertSheetRequest : NSObject <ComBelkadanKeystone_SheetRequest>
{
	id delegate;
	SEL didCloseSelector;
	void *contextInfo;

	NSString *label;
	NSAlert *alert;
}
- (id)initWithModalDelegate:(id)delegate didCloseSelector:(SEL)didCloseSelector contextInfo:(void *)contextInfo;

@property(readonly) NSAlert *alert;
@property(readwrite,copy) NSString *label;
@end


