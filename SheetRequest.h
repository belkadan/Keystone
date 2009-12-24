#import <Cocoa/Cocoa.h>

/*!
 * "Sheet requests" are how Safari handles sheets attached to tabs, rather than
 * windows. These method is actually implemented in BrowserWebView, a Safari-specific
 * subclass of WebView.
 */

@interface WebView (ComBelkadanKeystone_ActuallyInSafariSubclass)
/*!
 * Returns the current sheet request. Native Safari sheet requests are subclasses
 * of a SheetRequest /class/, which basically matches the protocol.
 */
- (id <ComBelkadanKeystone_SheetRequest>)sheetRequest;

/*!
 * Sets the current sheet request. If the web view's tab is active, the sheet
 * will be immediately displayed. Otherwise, the tab will request the user's
 * attention and display the sheet when it becomes active.
 */
- (void)setSheetRequest:(id <ComBelkadanKeystone_SheetRequest>)sheetRequest;
@end


/*!
 * Manages a sheet attached to a WebView, rather than a window. Safari handles
 * delaying the sheet until it's time to show it. In Safari, this is an actual
 * class called SheetRequest, but the class is hard to use.
 */
@protocol ComBelkadanKeystone_SheetRequest <NSObject>
/*!
 * Return a valid NSImage to show an icon on the associated tab, and nil to show no icon.
 * Note that the icon returned seems to have no effect on what is displayed!
 */
@property(readonly) NSImage *icon;

/*! The label to be shown on a tab while this request is pending. */
@property(readonly,copy) NSString *label;

/*! The sheet to be displayed. */
@property(readonly) NSWindow *window;

/*! Displays the sheet in the given window. */
- (void)displaySheetInWindow:(NSWindow *)window;

/*!
 * Displays the sheet. Whether this is intended to use the main window or to
 * display the sheet as a modal alert is unknown.
 */
- (void)displaySheet;
@end


/*! 
 * Provides a simple implementation of a SheetRequest for displaying NSAlert sheets. 
 * To use, create an AlertSheetRequest, then customize the NSAlert created in its
 * "alert" property, before finally setting it as a sheet request or displaying
 * it directly.
 */
@interface ComBelkadanKeystone_AlertSheetRequest : NSObject <ComBelkadanKeystone_SheetRequest>
{
	id delegate;
	SEL didCloseSelector;
	void *contextInfo;

	NSString *label;
	NSAlert *alert;
}
/*!
 * Returns a new alert sheet request with the given delegate, close selector, and
 * context info. The selector should be for a method matching this signature:
 *
 * - (void)alertSheetRequestDidClose:(ComBelkadanKeystone_AlertSheetRequest)alertSheetRequest
 *                        returnCode:(NSInteger)returnCode
 *                       contextInfo:(void *)contextInfo;
 */
- (id)initWithModalDelegate:(id)delegate didCloseSelector:(SEL)didCloseSelector contextInfo:(void *)contextInfo;

/*!
 * The alert associated with this sheet request. The alert is permanently
 * associated with this sheet request, and should be configured before the
 * sheet request is used.
 */
@property(readonly) NSAlert *alert;

/*! The label to be shown on a tab while this request is pending. */
@property(readwrite,copy) NSString *label;
@end


