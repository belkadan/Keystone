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
		
		NSInteger separatorIndex = [bookmarksMenu indexOfItem:[NSMenuItem separatorItem]];
		if (separatorIndex == -1) {
			[bookmarksMenu addItem:autodiscoverItem];
			[bookmarksMenu addItem:manualAddItem];
		} else {
			[bookmarksMenu insertItem:autodiscoverItem atIndex:separatorIndex];
			[bookmarksMenu insertItem:manualAddItem atIndex:separatorIndex+1];
		}

		[autodiscoverItem release];
		[manualAddItem release];
	}
}
@end
