#import "NSWindow+EndEditingGracefully.h"

#import <AppKit/NSText.h>
#import <AppKit/NSResponder.h>

@implementation NSWindow (ComBelkadanAppUtils_EndEditingGracefully)
- (void)endEditingGracefully
{
	// Courtesy of Daniel Jalkut, modified slightly
	// http://www.red-sweater.com/blog/229

	// Save the current first responder, respecting the fact
	// that it might conceptually be the delegate of the
	// field editor that is "first responder."
	id oldFirstResponder = [self firstResponder];
	if ((oldFirstResponder != nil) &&
		 [oldFirstResponder isKindOfClass:[NSText class]] &&
		 [oldFirstResponder isFieldEditor])
	{
	   // A field editor's delegate is the view we're editing
	   oldFirstResponder = [oldFirstResponder delegate];
	   if ([oldFirstResponder isKindOfClass:[NSResponder class]] == NO)
	   {
		  // Eh...we'd better back off if
		  // this thing isn't a responder at all
		  oldFirstResponder = nil;
	   }
	} 

	// Gracefully end all editing in our window (from Erik Buck).
	// This will cause the user's changes to be committed.
	if ([self makeFirstResponder:self])
	{
	   // All editing is now ended and delegate messages sent etc.
	}
	else
	{
	   // For some reason the text object being edited will
	   // not resign first responder status so force an
	   // end to editing anyway
	   [self endEditingFor:nil];
	}

	// If we had a first responder before, restore it
	if (oldFirstResponder != nil)
	{
	   [self makeFirstResponder:oldFirstResponder];
	}
}

- (IBAction)clearFirstResponder:(id)sender {
	[self performSelector:@selector(makeFirstResponder:) withObject:nil afterDelay:0];
}
@end
