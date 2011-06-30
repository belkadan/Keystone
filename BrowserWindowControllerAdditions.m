#import "BrowserWindowControllerAdditions.h"
#import "CompletionServer.h"
#import "AdditionalCompletionTableDataSource.h"
#import "FakeCompletionItem.h"

#import "LocationTextField.h"
#import "CompletionAdapter.h"
#import "SwizzleMacros.h"

#define KEYSTONE_PREFIX ComBelkadanKeystone_

static NSImage *smallKeystoneIcon = nil;

static BOOL completionIsVisible (struct CompletionController *completionController) {
	return [completionController->_window isVisible];
}

static BOOL completionIsActive (struct CompletionController *completionController) {
	return [completionController->_window isVisible] && ([completionController->_table selectedRow] != -1);
}

static BOOL shouldShowFavicon () {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"WebIconDatabaseEnabled"];
}

@interface ComBelkadanKeystone_BrowserWindowController () <ComBelkadanKeystone_AdditionalCompletionsDelegate>
- (IBAction)ComBelkadanKeystone_goToToolbarLocation:(id)sender;
- (void)ComBelkadanKeystone_controlTextDidChange:(NSNotification *)note;
- (void)ComBelkadanKeystone_controlTextDidEndEditing:(NSNotification *)note;
- (BOOL)ComBelkadanKeystone_control:(LocationTextField *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)command;
- (void)ComBelkadanKeystone_windowDidResignKey:(NSWindow *)window;
- (void)ComBelkadanKeystone__updateLocationFieldIconNow;
@end

@interface ComBelkadanKeystone_BrowserWindowController (ActuallyInBrowserWindowController)
- (LocationTextField *)locationField;
- (struct CompletionController *)_URLCompletionController;

- (IBAction)goToToolbarLocation:(id)sender;
- (void)_updateLocationFieldIconNow;
@end

@implementation ComBelkadanKeystone_BrowserWindowController
+ (void)initialize {
	if (self == [ComBelkadanKeystone_BrowserWindowController class]) {
		Class toClass = NSClassFromString(@"BrowserWindowController");
		if (!toClass) toClass = NSClassFromString(@"BrowserWindowControllerMac");

		COPY_METHOD(self, toClass, ComBelkadanKeystone_completionItemSelected:forQuery:);
		COPY_METHOD(self, toClass, ComBelkadanKeystone_completionItemChosen:forQuery:);

		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, goToToolbarLocation:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, controlTextDidChange:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, controlTextDidEndEditing:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, control:textView:doCommandBySelector:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, windowDidResignKey:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, _updateLocationFieldIconNow);

		smallKeystoneIcon = [[NSImage imageNamed:@"ComBelkadanKeystone_Preferences"] copy];
		[smallKeystoneIcon setSize:NSMakeSize(16, 16)];
	}	
}

- (void)ComBelkadanKeystone_controlTextDidChange:(NSNotification *)note {
	LocationTextField *locationField = [note object];
	if (locationField != [self locationField]) {
		// Don't catch other fields' warnings.
		[self ComBelkadanKeystone_controlTextDidChange:note];
		
	} else {
		// FIXME: This method is nearing atrocious (but isn't there yet).
		ComBelkadanKeystone_AdditionalCompletionTableDataSource *additionalDataSource = [ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance];

		NSTextView *editor = (NSTextView *)[locationField currentEditor];
		NSAssert(editor, @"Location field changed but it's not being edited.");
		NSString *completionString = [editor string];
		
		BOOL shouldAutocomplete;

		NSRange selection = [editor selectedRange];
		if (selection.length > 0) {
			completionString = [completionString substringToIndex:selection.location];
			shouldAutocomplete = YES;
		} else {
			shouldAutocomplete = (selection.location == [completionString length]);
		}

		if ([additionalDataSource isVisible]) {
			[additionalDataSource updateQuery:completionString autocomplete:shouldAutocomplete];
			
		} else if (shouldAutocomplete &&
				   [ComBelkadanKeystone_CompletionServer autocompleteForQueryString:completionString] &&
				   ![additionalDataSource wasCancelled]) {
			if (completionIsVisible([self _URLCompletionController])) {
				[self ComBelkadanKeystone_control:locationField textView:editor doCommandBySelector:@selector(cancelOperation:)];				
			}
			[additionalDataSource setDelegate:self];
			[additionalDataSource updateQuery:completionString autocomplete:shouldAutocomplete];
			[additionalDataSource showWindowForField:locationField];
			
		} else {
			// Don't do all the work of updating the query if we're not gonna show the window.
			[additionalDataSource clearCancelledIfChanged:completionString];
			[self ComBelkadanKeystone_controlTextDidChange:note];
		}
	}
}

- (void)ComBelkadanKeystone_controlTextDidEndEditing:(NSNotification *)note {
	[self ComBelkadanKeystone_controlTextDidEndEditing:note];

	LocationTextField *locationField = [note object];
	if (locationField == [self locationField]) {
		[locationField setDetailString:@""];
		[[ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance] cancelOperation:nil];
	}	
}

- (void)ComBelkadanKeystone_windowDidResignKey:(NSWindow *)window {
	[self ComBelkadanKeystone_windowDidResignKey:window];
	[[self locationField] setDetailString:@""];
	[[ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance] cancelOperation:nil];
}

- (BOOL)ComBelkadanKeystone_control:(LocationTextField *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)command {
	if (control == [self locationField]) {
		// FIXME: This method is atrocious.
		if (completionIsActive([self _URLCompletionController]))
			return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];

		// Special case for cancelOperation: -- clear the location field detail string.
		if (command == @selector(cancelOperation:)) {
			if ([self respondsToSelector:@selector(_updateLocationFieldIconNow)]) {
				[self _updateLocationFieldIconNow];
			} else {
				[control setDetailString:@""];
			}
		}

		ComBelkadanKeystone_AdditionalCompletionTableDataSource *additionalDataSource = [ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance];

		BOOL response = [additionalDataSource tryToPerform:command with:nil];
		if (response) return YES;

		// Special case for deletion, which hides the completions but also needs to delete.
		if (command == @selector(deleteBackward:) || command == @selector(deleteForward:)) {
			[additionalDataSource cancelOperation:nil];
			
		} else if (command == @selector(moveUp:)) {
			// Special case for moveUp: -- this is how we toggle from one set of shortcuts to the other.
			if ([additionalDataSource isVisible]) {
				[additionalDataSource cancelOperation:nil];

				// Bring back the regular set by deleting the selection.
				if ([fieldEditor selectedRange].length > 0)
					[fieldEditor deleteBackward:nil];
				else
					// If there's no selection, just send a notification ourself.
					// We use the original version so as not to clear the cancel flag.
					[self ComBelkadanKeystone_controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:control]];
				return YES;

			} else {
				[self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:@selector(cancelOperation:)];
				[additionalDataSource setDelegate:self];

				NSString *completionString = [fieldEditor string];
				NSRange selection = [fieldEditor selectedRange];
				if (selection.length > 0)
					completionString = [completionString substringToIndex:selection.location];
				[additionalDataSource updateQuery:completionString autocomplete:YES];
			
				[additionalDataSource showWindowForField:control];
				return YES;
			}

		} else if (command == @selector(moveDown:) && !completionIsVisible([self _URLCompletionController])) {
			// If neither completion set is visible, moveDown: brings back the default ones...
			// ...by deleting the selection.
			if ([fieldEditor selectedRange].length > 0)
				[fieldEditor deleteBackward:nil];
			else
				// If there's no selection, just send a notification ourself.
				[self ComBelkadanKeystone_controlTextDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:control]];
			return YES;
		}
	}
	return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];
}

- (IBAction)ComBelkadanKeystone_goToToolbarLocation:(id)sender {
	LocationTextField *locationField = [self locationField];
	NSString *completionString = [locationField stringValue];
	
	ComBelkadanKeystone_FakeCompletionItem *completion = [ComBelkadanKeystone_CompletionServer autocompleteForQueryString:completionString];
	if (completion) {
		[locationField setStringValue:[completion urlStringForQueryString:completionString]];		
	}

	[self ComBelkadanKeystone_goToToolbarLocation:sender];
}

- (void)ComBelkadanKeystone__updateLocationFieldIconNow {
	LocationTextField *locationField = [self locationField];
	[locationField setDetailString:@""];
	[self ComBelkadanKeystone__updateLocationFieldIconNow];
}

#pragma mark -

- (void)ComBelkadanKeystone_completionItemSelected:(ComBelkadanKeystone_FakeCompletionItem *)completion forQuery:(NSString *)query {
	LocationTextField *locationField = [self locationField];
	if (completion) {
		NSTextView *editor = (NSTextView *)[locationField currentEditor];
		NSAssert(editor, @"Completion item selected but location field is not being edited.");
		NSRange oldSelection = [editor selectedRange];
		NSRange selection = NSMakeRange(0, 0);

		// FIXME: This cast sucks, but really it's being used as an unsigned integer.
		// So...need to fix -reflectedStringForQueryString:withSelectionFrom:
		NSString *replacement = [completion reflectedStringForQueryString:query withSelectionFrom:(NSInteger *)&selection.location];
		[editor shouldChangeTextInRange:NSMakeRange(0, [[editor string] length]) replacementString:replacement];
		[editor setString:replacement];

		NSUInteger replacementLength = [replacement length];
		if (selection.location == replacementLength && oldSelection.location < [replacement length]) {
			[editor setSelectedRange:oldSelection];
		} else {
			selection.length = replacementLength - selection.location;
			[editor setSelectedRange:selection];
		}
		
		//[locationField setDetailString:[completion previewURLStringForQueryString:query]];
		if (shouldShowFavicon())
			[locationField setIcon:smallKeystoneIcon];
	} else {
		[locationField setDetailString:@""];
	}
}

- (void)ComBelkadanKeystone_completionItemChosen:(ComBelkadanKeystone_FakeCompletionItem *)completion forQuery:(NSString *)query {
	NSAssert(completion != nil, @"Nil completion item chosen");
	LocationTextField *locationField = [self locationField];
	[locationField setStringValue:[completion urlStringForQueryString:query]];
	[locationField performClick:nil];
}

@end
