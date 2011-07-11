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
	id value = [[NSUserDefaults standardUserDefaults] objectForKey:@"WebIconDatabaseEnabled"];
	return !value || [value boolValue];
}

@interface ComBelkadanKeystone_BrowserWindowController () <ComBelkadanKeystone_AdditionalCompletionsDelegate>
- (IBAction)ComBelkadanKeystone_goToToolbarLocation:(id)sender;
- (void)ComBelkadanKeystone_controlTextDidChange:(NSNotification *)note;
- (void)ComBelkadanKeystone_controlTextDidEndEditing:(NSNotification *)note;
- (BOOL)ComBelkadanKeystone_control:(LocationTextField *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)command;
- (void)ComBelkadanKeystone_windowDidResignKey:(NSWindow *)window;

- (void)ComBelkadanKeystone_showSafariCompletionsWithFieldEditor:(NSTextView *)fieldEditor;
@end

@protocol ComBelkadanKeystone_WKView
- (void *)pageRef;
@end


@interface ComBelkadanKeystone_BrowserWindowController (ActuallyInBrowserWindowController)
- (LocationTextField *)locationField;
- (struct CompletionController *)_URLCompletionController;

- (IBAction)goToToolbarLocation:(id)sender;
- (void)_updateLocationFieldIconNow;

- (void)safariBrowserWindowUpdateLocationFieldIconNow:(void *)pageRef;
- (id <ComBelkadanKeystone_WKView>)currentBrowserOrOverlayWebView;
@end

@implementation ComBelkadanKeystone_BrowserWindowController
+ (void)initialize {
	if (self == [ComBelkadanKeystone_BrowserWindowController class]) {
		Class toClass = NSClassFromString(@"BrowserWindowController");
		if (!toClass) toClass = NSClassFromString(@"BrowserWindowControllerMac");

		COPY_METHOD(self, toClass, ComBelkadanKeystone_completionItemSelected:forQuery:);
		COPY_METHOD(self, toClass, ComBelkadanKeystone_completionItemChosen:forQuery:);
		COPY_METHOD(self, toClass, ComBelkadanKeystone_showSafariCompletionsWithFieldEditor:);

		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, goToToolbarLocation:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, controlTextDidChange:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, controlTextDidEndEditing:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, control:textView:doCommandBySelector:);
		COPY_AND_EXCHANGE(self, toClass, KEYSTONE_PREFIX, windowDidResignKey:);
		
		if (![toClass instancesRespondToSelector:@selector(_updateLocationFieldIconNow)]) {
			// This method was replaced in Safari 5.1 to deal with the new multiprocess rendering model.
			// We emulate the old behavior.
			COPY_METHOD(self, toClass, _updateLocationFieldIconNow);
		}

		smallKeystoneIcon = [[NSImage imageNamed:@"ComBelkadanKeystone_Preferences"] copy];
		[smallKeystoneIcon setSize:NSMakeSize(16, 16)];
	}	
}

- (void)ComBelkadanKeystone_controlTextDidChange:(NSNotification *)note {
	LocationTextField *locationField = [note object];
	if (locationField != [self locationField]) {
		// Don't catch other fields' notifications.
		[self ComBelkadanKeystone_controlTextDidChange:note];
		return;
	}
		
	ComBelkadanKeystone_AdditionalCompletionTableDataSource *additionalDataSource = [ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance];

	NSTextView *editor = (NSTextView *)[locationField currentEditor];
	NSAssert(editor, @"Location field changed but it's not being edited.");
	NSString *completionString = [editor string];
	
	// Don't autocomplete if the insertion point is in the middle of a string.
	// Also, ignore anything selected at the end of the string.
	BOOL shouldAutocomplete;

	NSRange selection = [editor selectedRange];
	if (selection.length > 0) {
		completionString = [completionString substringToIndex:selection.location];
		shouldAutocomplete = YES;
	} else {
		shouldAutocomplete = (selection.location == [completionString length]);
	}

	if ([additionalDataSource isVisible]) {
		// If Keystone's data source is up, just update it.
		[additionalDataSource updateQuery:completionString autocomplete:shouldAutocomplete];
		
	} else if (shouldAutocomplete && ![additionalDataSource wasCancelled] &&
			   [ComBelkadanKeystone_CompletionServer autocompleteForQueryString:completionString]) {
		// If Keystone's data source is not up but should be, show it.
		if (completionIsVisible([self _URLCompletionController])) {
			[self ComBelkadanKeystone_control:locationField textView:editor doCommandBySelector:@selector(cancelOperation:)];				
		}
		[additionalDataSource setDelegate:self];
		[additionalDataSource updateQuery:completionString autocomplete:shouldAutocomplete];
		[additionalDataSource showWindowForField:locationField];
		
	} else {
		// Otherwise, let the default completions go ahead.
		// Don't do all the work of updating the query if we're not gonna show the window.
		[additionalDataSource clearCancelledIfChanged:completionString];
		[self ComBelkadanKeystone_controlTextDidChange:note];
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
	if (control != [self locationField]) {
		// Don't catch other fields' commands.
		return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];
	}
	
	ComBelkadanKeystone_AdditionalCompletionTableDataSource *additionalDataSource = [ComBelkadanKeystone_AdditionalCompletionTableDataSource sharedInstance];

	// If the default completions are active, we should NOT take over the completions.
	if (completionIsActive([self _URLCompletionController])) {
		[additionalDataSource cancelOperation:nil];
		return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];
	}

	// If our completions are active, give them first crack at the command.
	// This is (roughly) the same behavior as when Safari's completion window is active.
	BOOL response = [additionalDataSource tryToPerform:command with:nil];
	if (response) return YES;

	// Handle certain commands specially.
	if (command == @selector(deleteBackward:) || command == @selector(deleteForward:)) {
		// Deletion hides Keystone's completions before actually deleting.
		[additionalDataSource cancelOperation:nil];
		return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];
		
	} else if (command == @selector(moveUp:)) {
		// moveUp: toggles from one set of shortcuts to the other.
		if ([additionalDataSource isVisible]) {
			// Kill our completions, show Safari's.
			[additionalDataSource cancelOperation:nil];
			[self ComBelkadanKeystone_showSafariCompletionsWithFieldEditor:fieldEditor];
			return YES;

		} else {
			// Kill Safari's completions, show Keystone's.
			[self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:@selector(cancelOperation:)];

			// Claim the Keystone completions.
			[additionalDataSource setDelegate:self];

			// Figure out what we're supposed to be completing.
			NSString *completionString = [fieldEditor string];
			NSRange selection = [fieldEditor selectedRange];
			if (selection.length > 0)
				completionString = [completionString substringToIndex:selection.location];
			[additionalDataSource updateQuery:completionString autocomplete:YES];

			// Show our completions.
			[additionalDataSource showWindowForField:control];
			return YES;
		}

	} else if (command == @selector(moveDown:) && !completionIsVisible([self _URLCompletionController])) {
		// If neither completion set is visible, moveDown: brings back the default ones...
		[self ComBelkadanKeystone_showSafariCompletionsWithFieldEditor:fieldEditor];
		return YES;				

	} else {
		// Give up. Let Safari handle this command as usual.
		return [self ComBelkadanKeystone_control:control textView:fieldEditor doCommandBySelector:command];
	}
}

- (void)ComBelkadanKeystone_showSafariCompletionsWithFieldEditor:(NSTextView *)fieldEditor {	
	// Bring back the regular completions by deleting the selection.
	if ([fieldEditor selectedRange].length > 0) {
		[fieldEditor deleteBackward:nil];		
	} else {
		// If there's no selection, just send a fake notification ourself.
		// We use the original version so as not to clear the cancel flag.
		NSNotification *note = [NSNotification notificationWithName:NSControlTextDidChangeNotification object:[self locationField] userInfo:[NSDictionary dictionaryWithObject:fieldEditor forKey:@"NSFieldEditor"]];
		[self ComBelkadanKeystone_controlTextDidChange:note];
	}
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

#pragma mark -

- (void)ComBelkadanKeystone_completionItemSelected:(ComBelkadanKeystone_FakeCompletionItem *)completion forQuery:(NSString *)query {
	if (!completion) {
		[self _updateLocationFieldIconNow];
		return;
	}

	LocationTextField *locationField = [self locationField];

	NSTextView *editor = (NSTextView *)[locationField currentEditor];
	NSAssert(editor, @"Completion item selected but location field is not being edited.");
	NSRange oldSelection = [editor selectedRange];
	NSRange selection = NSMakeRange(0, 0);

	NSString *replacement = [completion reflectedStringForQueryString:query withSelectionFrom:&selection.location];
	[editor shouldChangeTextInRange:NSMakeRange(0, [[editor string] length]) replacementString:replacement];
	[editor setString:replacement];

	NSUInteger replacementLength = [replacement length];
	if (selection.location == replacementLength && oldSelection.location < [replacement length]) {
		[editor setSelectedRange:oldSelection];
	} else {
		selection.length = replacementLength - selection.location;
		[editor setSelectedRange:selection];
	}
	
	if (shouldShowFavicon())
		[locationField setIcon:smallKeystoneIcon];
}

- (void)ComBelkadanKeystone_completionItemChosen:(ComBelkadanKeystone_FakeCompletionItem *)completion forQuery:(NSString *)query {
	NSAssert(completion != nil, @"Nil completion item chosen");

	LocationTextField *locationField = [self locationField];
	NSTextView *editor = (NSTextView *)[locationField currentEditor];
	NSAssert(editor, @"Completion item selected but location field is not being edited.");
	[editor setString:[completion urlStringForQueryString:query]];
	[editor insertNewline:nil];
}

- (void)_updateLocationFieldIconNow {
	// This method was replaced in Safari 5.1 to deal with the new multiprocess rendering model.
	// We emulate the old behavior by reaching in and finding the current page.
	if ([self respondsToSelector:@selector(safariBrowserWindowUpdateLocationFieldIconNow:)]) {
		[self safariBrowserWindowUpdateLocationFieldIconNow:[[self currentBrowserOrOverlayWebView] pageRef]];
	}
}

@end
