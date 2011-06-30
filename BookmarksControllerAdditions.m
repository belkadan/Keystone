#import "BookmarksControllerAdditions.h"
#import "KeystoneController.h"

#import "SwizzleMacros.h"

#define KEYSTONE_PREFIX ComBelkadanKeystone_

@interface ComBelkadanKeystone_BookmarksControllerObjC ()
- (void)ComBelkadanKeystone__resetMenu;
@end

@implementation ComBelkadanKeystone_BookmarksControllerObjC
+ (void)initialize {
	Class BookmarksControllerObjC_class = NSClassFromString(@"BookmarksControllerObjC");
	COPY_AND_EXCHANGE([self class], BookmarksControllerObjC_class, KEYSTONE_PREFIX, _resetMenu);
	[[BookmarksControllerObjC_class sharedController] _resetMenu];
}

- (void)ComBelkadanKeystone__resetMenu {
	[self ComBelkadanKeystone__resetMenu];

	NSMenu *bookmarksMenu;
	object_getInstanceVariable(self, "_bookmarksMenu", (void**)&bookmarksMenu);

	if (bookmarksMenu && [bookmarksMenu indexOfItemWithRepresentedObject:[ComBelkadanKeystone_BookmarksControllerObjC class]] == -1) {
		NSString *autodiscoverTitle = NSLocalizedStringFromTableInBundle(@"Add Keystone Completion...", @"Localizable", [NSBundle bundleForClass:[ComBelkadanKeystone_Controller class]], @"Autodiscovery menu item title");
		NSMenuItem *autodiscoverItem = [[NSMenuItem alloc] initWithTitle:autodiscoverTitle action:@selector(attemptAutodiscovery:) keyEquivalent:@""];
		[autodiscoverItem setTarget:[ComBelkadanKeystone_Controller sharedInstance]];
		[autodiscoverItem setRepresentedObject:[ComBelkadanKeystone_BookmarksControllerObjC class]];
		
		NSString *manualAddTitle = NSLocalizedStringFromTableInBundle(@"Add Manual Keystone Shortcut...", @"Localizable", [NSBundle bundleForClass:[ComBelkadanKeystone_Controller class]], @"Autodiscovery menu item title");
		NSMenuItem *manualAddItem = [[NSMenuItem alloc] initWithTitle:manualAddTitle action:@selector(newCompletionForCurrentPage:) keyEquivalent:@""];
		[manualAddItem setTarget:[ComBelkadanKeystone_Controller sharedInstance]];
		[manualAddItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
		[manualAddItem setAlternate:YES];
		
		NSInteger index = 0;
		for (NSMenuItem *menuItem in [bookmarksMenu itemArray]) {
			if ([menuItem isSeparatorItem]) {
				[bookmarksMenu insertItem:autodiscoverItem atIndex:index];
				[bookmarksMenu insertItem:manualAddItem atIndex:index+1];
				break;
			}
			++index;
		}
		
		if ([autodiscoverItem menu] == nil) {
			// This isn't a great fallback, but it shouldn't ever happen anyway.
			[bookmarksMenu addItem:autodiscoverItem];
			[bookmarksMenu addItem:manualAddItem];
		}

		[autodiscoverItem release];
		[manualAddItem release];
	}
}
@end
