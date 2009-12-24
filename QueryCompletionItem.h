#import "FakeCompletionItem.h"
#import <Cocoa/Cocoa.h>

/*! A (non-localized) name for default actions. */
extern NSString * const ComBelkadanKeystone_kDefaultActionKeyword;
/*! The part of a completion URL to be replaced by a query. */
extern NSString * const ComBelkadanKeystone_kSubstitutionMarker;

/*!
 * A Keystone completion item that replaces a marker in a URL with a query entered
 * by the user. For example:
 * "wiki this" + http://en.wikipedia.org/wiki/%% = http://en.wikipedia.org/wiki/this
 */
@interface ComBelkadanKeystone_QueryCompletionItem : ComBelkadanKeystone_FakeCompletionItem {
	NSString *name;
	NSString *keyword;
	NSString *shortcutURL;
}

/*! The designated initializer. */
- (id)initWithName:(NSString *)givenName keyword:(NSString *)givenKeyword shortcutURL:(NSString *)URLString;

/*! The name shown for this completion. */
@property (readwrite,copy) NSString *name;
/*! The shortcut URL, as a string, which may or may not contain substitution markers. */
@property (readwrite,copy) NSString *URL;
/*! The keyword used to trigger this completion. */
@property (readwrite,copy) NSString *keyword;
@end

