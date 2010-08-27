#import "BrowserWindowControllerAdditions.h"
#import "CompletionControllerAdditions.h"
#import "AdditionalCompletionTableDataSource.h"
#import "LocationTextField.h"
#import "FakeCompletionItem.h"
#import "CompletionAdapter.h"
#import "SwizzleMacros.h"

struct SNotification {
    NSString *name;
    void *object;
    struct HashMap *userInfo;
};

#define KEYSTONE_PREFIX ComBelkadanKeystone_
#define CharFromBool(B) ((B) ? 'Y' : 'N')

static NSMapTable *additionalResultsTable = nil;
static NSImage *smallKeystoneIcon = nil;

static BOOL completionIsActive (struct CompletionController *completionController) {
	return [completionController->_window isVisible] && ([completionController->_table selectedRow] != -1);
}

@interface ComBelkadanKeystone_BrowserWindowController () <ComBelkadanKeystone_AdditionalCompletionsDelegate>
- (void)ComBelkadanKeystone_updateLocationField;
@end

@interface ComBelkadanKeystone_BrowserWindowController (ActuallyInBrowserWindowController)
- (LocationTextField *)locationField;
- (struct CompletionController *)_URLCompletionController;
@end

@implementation ComBelkadanKeystone_BrowserWindowController
+ (void)initialize {
	Class fromClass = [self class];
	if (fromClass == [ComBelkadanKeystone_BrowserWindowController class]) {
		Class toClass = NSClassFromString(@"BrowserWindowController");

		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_updateLocationField);
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_completionItemSelected:);
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_completionItemChosen:);
		
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, goToToolbarLocation:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, controlTextDidChange:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, controlTextDidEndEditing:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, control:textView:doCommandBySelector:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, windowDidResignKey:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, _updateLocationFieldIconNow);

		smallKeystoneIcon = [[NSImage imageNamed:@"ComBelkadanKeystone_Preferences"] copy];
		[smallKeystoneIcon setSize:NSMakeSize(16, 16)];
	}	
}

- (void)ComBelkadanKeystone_controlTextDidChange:(NSNotification *)note {
	[self ComBelkadanKeystone_controlTextDidChange:note];

	LocationTextField *locationField = [note object];
	if (locationField == [self locationField]) {
		[self ComBelkadanKeystone_updateLocationField];
	}
}

- (void)ComBelkadanKeystone_controlTextDidEndEditing:(NSNotification *)note {
	[self ComBelkadanKeystone_controlTextDidEndEditing:note];

	LocationTextField *locationField = [note object];
	if (locationField == [self locationField]) {
		[[ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance] cancelOperation:nil];
	}	
}

- (void)ComBelkadanKeystone_windowDidResignKey:(NSWindow *)window {
	[self ComBelkadanKeystone_windowDidResignKey:window];
	[[ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance] cancelOperation:nil];
}

- (BOOL)ComBelkadanKeystone_control:(LocationTextField *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)command {
	if (control == [self locationField]) {
		if (completionIsActive([self _URLCompletionController]))
			return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];

		ComBelkadanKeystone_AdditionalCompletionTableDataSource *additionalDataSource = [ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance];

		// Special case for moveUp: -- this is how we toggle from one set of shortcuts to the other.
		if (command == @selector(moveUp:)) {
			if ([additionalDataSource isActive]) {
				BOOL response = [additionalDataSource tryToPerform:command with:nil];
				if (response) return YES;

			} else if ([additionalDataSource isVisible]) {
				[self controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:control]];
				[additionalDataSource cancelOperation:nil];
				return YES;

			} else {
				[self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:@selector(cancelOperation:)];
				[additionalDataSource setDelegate:self];
				[additionalDataSource updateQuery:[fieldEditor string]];
				[additionalDataSource showWindowForField:control];
				return YES;
			}
		}

		if ([additionalDataSource isVisible]) {
			BOOL response = [additionalDataSource tryToPerform:command with:nil];
			if (response) return YES;
		}

		if (command == @selector(moveDown:)) {
			// If neither completions are visible, moveDown: brings back the default ones by deleting the selection.
			if ([fieldEditor selectedRange].length > 0)
				[fieldEditor deleteBackward:nil];
			// If there's no selection, just send a notification ourself.
			[self controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:control]];
			return YES;
		}
	}
	return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];
}

- (IBAction)ComBelkadanKeystone_goToToolbarLocation:(id)sender {
	LocationTextField *locationField = [self locationField];
	NSString *completionString = [locationField untruncatedStringValue];
	
	if ([completionString ComBelkadanKeystone_queryWantsCompletion]) {
		ComBelkadanKeystone_FakeCompletionItem *completion = [ComBelkadanKeystone_URLCompletionController firstItemForQueryString:completionString];
		if (completion) {
			[locationField setStringValue:[completion urlStringForQueryString:completionString]];
		}
	}

	[self ComBelkadanKeystone_goToToolbarLocation:sender];
}

- (void)ComBelkadanKeystone__updateLocationFieldIconNow {
	[self ComBelkadanKeystone__updateLocationFieldIconNow];
	[self ComBelkadanKeystone_updateLocationField];
}

- (void)ComBelkadanKeystone_updateLocationField {
	LocationTextField *locationField = [self locationField];
	NSString *completionString = [locationField untruncatedStringValue];
	struct CompletionController *completionController = [self _URLCompletionController];
	if (completionIsActive(completionController) && [completionString ComBelkadanKeystone_queryWantsCompletion]) {
		ComBelkadanKeystone_FakeCompletionItem *completion = [ComBelkadanKeystone_URLCompletionController firstItemForQueryString:completionString];
		if (completion) {
			[locationField setDetailString:[completion urlStringForQueryString:completionString]];
			[locationField setIcon:smallKeystoneIcon];
		} else {
			[locationField setDetailString:@""];
		}
	} else {
		[locationField setDetailString:@""];
	}
}

#pragma mark -

- (void)ComBelkadanKeystone_completionItemSelected:(ComBelkadanKeystone_FakeCompletionItem *)completion {
	LocationTextField *locationField = [self locationField];
	if (completion) {
		NSString *completionString = [locationField untruncatedStringValue];
		[locationField setDetailString:[completion urlStringForQueryString:completionString]];
		[locationField setIcon:smallKeystoneIcon];
	} else {
		[locationField setDetailString:@""];
	}
}

- (void)ComBelkadanKeystone_completionItemChosen:(ComBelkadanKeystone_FakeCompletionItem *)completion {
	NSAssert(completion != nil, @"Nil completion item chosen");
	LocationTextField *locationField = [self locationField];
	NSString *completionString = [locationField untruncatedStringValue];
	[locationField setStringValue:[completion urlStringForQueryString:completionString]];
	[locationField performClick:nil];
}

@end
