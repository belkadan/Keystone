#import <Cocoa/Cocoa.h>

/*!
 * Abstract superclass of all Keystone completion items.
 *
 * Subclasses must have name and URL properties. If both of these properties are
 * static, you can use SimpleCompletionItem, rather than making your own subclass.
 */
@interface ComBelkadanKeystone_FakeCompletionItem : NSObject {
}

/*!
 * Returns a separator. Since a separator extends across across the entire menu
 * in Safari 4, you should think twice before including them in your code.
 * Keystone's completion handler controller uses separators to divide different
 * sources' available completions.
 */
+ (ComBelkadanKeystone_FakeCompletionItem *)separatorItem;

@property(readonly,copy) NSString *name;
@property(readonly,copy) NSString *URL;

/*!
 * If YES, the item should be displayed as a header, rather than a selectable completion item.
 * By default, items without URLs (self.URL == nil) are treated as headers.
 * In Safari 4, the URL property is not displayed.
 */
@property(readonly) BOOL isHeader;

/*!
 * If YES, the item should be displayed as a separator.
 * By default, items without names (self.name == nil) are treated as separators.
 * In Safari 4, this displays as a menu separator (i.e. without any text).
 */
@property(readonly) BOOL isSeparator;

/*!
 * If YES, matches against the query string are performed insensitively.
 * Defaults to YES.
 */
@property(readonly) BOOL caseInsensitive;

/*!
 * If an item is at the top of the completions list and this method returns YES,
 * it will be invoked when the user presses Enter. By default, this method only
 * returns YES if the query has a space in it (thus guaranteed to not be a URL).
 *
 * Subclasses should be careful not to return YES if the query could be a usual
 * URL or URL fragment (such as "belkadan.com"). Don't frustrate the user.
 */
- (BOOL)canBeFirstSelectedForQueryString:(NSString *)query;

/*!
 * Returns YES if the query isn't just a prefix of the completion, but an actual
 * full match. For keyword search, for example, the entire keyword should match.
 * This is used to determine "steal" behavior -- whether or not a given query
 * should show Keystone completions over Safari's default completions and so on.
 *
 * Subclasses should be careful not to return YES if the query could be a usual
 * URL (such as "belkadan.com"). However, unlike -canBeFirstSelectedForQueryString:,
 * it is all right to steal URL fragments ("belkadan"), since they may be user-
 * defined shortcuts.
 */
- (BOOL)isExactMatchForQueryString:(NSString *)query;
 
/*!
 * Returns a version of the name suitable for display in the completions menu
 * for a given query. By default, simply returns self.name.
 */
- (NSString *)nameForQueryString:(NSString *)query;

/*!
 * Returns a version of the destination suitable for display in the completions menu
 * for a given query. By default, simply returns [self urlForQueryString:query].
 */
- (NSString *)previewURLStringForQueryString:(NSString *)query;

/*!
 * Returns the actual destination URL string that will be put back into the location
 * bar when the user presses Enter. By default, simply returns self.URL.
 */
- (NSString *)urlStringForQueryString:(NSString *)query;

/*!
 * Returns the string shown in the location bar as the user is typing their query.
 * In addition, a character index can be returned in the selectionStart parameter;
 * text in the location bar will be selected from that index to the end of the string.
 * By default this returns self.name, highlighting the part of the name that's not
 * part of the user's query.
 */
- (NSString *)reflectedStringForQueryString:(NSString *)query withSelectionFrom:(NSUInteger *)selectionStart;

@end


/*!
 * A concrete subclass of FakeCompletionItem, used for static completion items
 * (including headers).
 *
 * Simple completion items are constant objects, so if a value changes, you need
 * to make a new completion item.
 */
@interface ComBelkadanKeystone_SimpleCompletionItem : ComBelkadanKeystone_FakeCompletionItem {
	NSString *name;
	NSString *URL;
}

/*! The designated initializer. Pass nil for the urlString param to create a header item. */
- (id)initWithName:(NSString *)name URLString:(NSString *)URLString;

@end

