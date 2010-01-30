#import "UpdateController.h"

#import "SwizzleMacros.h"
#import <objc/objc-api.h>

static IMP UpdatePermissionPrompt_promptDescription = NULL;

@interface NSObject (ComBelkadanKeystone_ActuallyOnSUUpdatePermissionPrompt)
- (NSString *)promptDescription;
@end

@interface NSObject (ComBelkadanKeystone_WebKitSparkleBranchDelegateMethods)
- (NSString *)descriptionTextForUpdatePermissionPrompt:(id)prompt;
- (NSString *)permissionPromptDescriptionTextForUpdater:(SUUpdater *)updater;
@end


static NSString *WebKit_SUUpdatePermissionPrompt_promptDescription (id self, SEL _cmd) {
	id delegate;
	object_getInstanceVariable(self, "delegate", (void**)&delegate);

	// Based on the WebKit branch of Sparkle
	NSString *text;
	if ([delegate respondsToSelector:@selector(descriptionTextForUpdatePermissionPrompt:)]) {
		text = [delegate descriptionTextForUpdatePermissionPrompt:self];
	}
	
	return (text ? text : UpdatePermissionPrompt_promptDescription(self, _cmd));
}

static NSString *WebKit_SUUpdater_descriptionTextForUpdatePermissionPrompt_ (id self, SEL _cmd, id prompt) {
	id delegate = [self delegate];

	NSString *text = nil;
	if ([delegate respondsToSelector:@selector(permissionPromptDescriptionTextForUpdater:)]) {
		text = [delegate permissionPromptDescriptionTextForUpdater:(SUUpdater *)self];
	}

	return text;
}


@implementation ComBelkadanKeystone_SparkleCompatibilityController

+ (void)initialize {
	if (self == [ComBelkadanKeystone_SparkleCompatibilityController class]) {
		// Only load Sparkle if another bundle hasn't yet (i.e. WebKit)
		// Loading different versions of a framework is a Bad Idea
		Class SUUpdater_class = NSClassFromString(@"SUUpdater");
		if (SUUpdater_class == Nil) {
			NSString *sparklePath =
				[[[[[NSBundle bundleForClass:[self class]] bundlePath]
					stringByAppendingPathComponent:@"Contents"]
						stringByAppendingPathComponent:@"Frameworks"]
							stringByAppendingPathComponent:@"Sparkle.framework"];
			[[NSBundle bundleWithPath:sparklePath] load];
			SUUpdater_class = NSClassFromString(@"SUUpdater");
		}
		
		if (![SUUpdater_class respondsToSelector:@selector(descriptionTextForUpdatePermissionPrompt:)]) {
			// We're using a non-WebKit version of Sparkle
			// Swap in WebKit's version of -promptDescription
			// and add the associated delegate method
			UpdatePermissionPrompt_promptDescription = class_replaceMethod(
				NSClassFromString(@"SUUpdatePermissionPrompt"), @selector(promptDescription),
				(IMP)WebKit_SUUpdatePermissionPrompt_promptDescription, "@:@"); // id (self, _cmd)
				
			class_addMethod(SUUpdater_class, @selector(descriptionTextForUpdatePermissionPrompt:),
				(IMP)WebKit_SUUpdater_descriptionTextForUpdatePermissionPrompt_, "@@:@"); // id (self, _cmd, id)
		}
	}
}

+ (id)updaterForBundle:(NSBundle *)bundle {
	Class SUUpdater_class = NSClassFromString(@"SUUpdater");
	if ([SUUpdater_class respondsToSelector:@selector(updaterForBundle:)]) {
		return [SUUpdater_class updaterForBundle:bundle];
	} else {
		return nil;
	}
}

@end
