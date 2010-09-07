#import "CompletionControllerAdditions.h"

#import "CompletionServer.h"
#import "FakeCompletionItem.h"
#import "CompletionHandler.h"
#import "CompletionControllers.h"

#import "SwizzleMacros.h"

#define KEYSTONE_PREFIX ComBelkadanKeystone_
	
@interface ComBelkadanKeystone_URLCompletionController (ActuallyInURLCompletionController)
- (NSString *)queryString;

- (NSTextField *)_sourceField;
- (NSView *)deepestViewContainingSourceField;
- (NSString *)sourceFieldString;
- (void)setSourceFieldString:(NSString *)newString;
- (void)replaceSourceFieldCharactersInRange:(NSRange)range withString:(NSString *)replacement selectingFromIndex:(NSInteger)fromIndex;
- (void)performSourceFieldAction;
- (void)sourceFieldTextDidChange;

- (NSDictionary *)attributesForListItem:(id)item column:(NSUInteger)col row:(NSUInteger)row forceDisabledColor:(BOOL)forceDisabled;
- (NSArray *)currentListItems;
- (id)selectedListItem;

- (BOOL)startsWithFirstItemSelected;
- (BOOL)completionListActsLikeMenu;
@end

@interface ComBelkadanKeystone_URLCompletionController ()
- (NSArray *)ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:(NSUInteger *)indexRef;

- (BOOL)ComBelkadanKeystone_doSourceFieldCommandBySelector:(SEL)command;
- (BOOL)ComBelkadanKeystone_isEditing;

- (void)ComBelkadanKeystone_reflectSelectedListItem;
- (BOOL)ComBelkadanKeystone_activateSelectedListItem;

- (BOOL)ComBelkadanKeystone_listItemIsChecked:(ComBelkadanKeystone_FakeCompletionItem *)item;
- (BOOL)ComBelkadanKeystone_listItemIsSeparator:(ComBelkadanKeystone_FakeCompletionItem *)item;
- (BOOL)ComBelkadanKeystone_listItemIsSelectable:(ComBelkadanKeystone_FakeCompletionItem *)item;
- (NSAttributedString *)ComBelkadanKeystone_displayedStringForListItem:(id)item column:(NSUInteger)col row:(NSUInteger)row;
@end


@implementation ComBelkadanKeystone_URLCompletionController
+ (void)initialize {
	if (self != [ComBelkadanKeystone_URLCompletionController class])
		return;

	Class completionControllerClass = NSClassFromString(@"URLCompletionController");
	if (completionControllerClass == Nil) completionControllerClass = NSClassFromString(@"OldURLCompletionController");
	if (!completionControllerClass) {
		NSLog(@"No completion controller found. Keystone completions are not active.");
		return;
	}

	if (![completionControllerClass instancesRespondToSelector:@selector(ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:)]) {
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, computeListItemsAndInitiallySelectedIndex:);
		COPY_METHOD(self, completionControllerClass, ComBelkadanKeystone_isEditing);
		
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, listItemIsSeparator:);
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, listItemIsSelectable:);
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, listItemIsChecked:);
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, reflectSelectedListItem);
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, activateSelectedListItem);
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, displayedStringForListItem:column:row:);
		COPY_AND_EXCHANGE(self, completionControllerClass, KEYSTONE_PREFIX, doSourceFieldCommandBySelector:);
		
		// will fail if on Safari 4.0.0-2, which already has these method around
		// our versions are placeholders that "do the right thing" based on the Safari 4.0.3 context
		COPY_METHOD(self, completionControllerClass, completionListActsLikeMenu);
		COPY_METHOD(self, completionControllerClass, sourceField);
	}
}

#pragma mark -

/*! Swizzle-wrapped: add fake completion items from all sources following existing completions */
- (NSArray *)ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:(NSUInteger *)indexRef {
	if (indexRef) *indexRef = NSNotFound;

	NSMutableArray *results = [[self ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:indexRef] mutableCopy];
	
	// only complete if (a) Apple thinks we should, or (b) there's an edit going on
	NSUInteger normalCount = [results count];
	if (normalCount > 0 || [self ComBelkadanKeystone_isEditing]) {
		NSString *query = [self queryString];
		BOOL useHeaders = [self completionListActsLikeMenu];
		[ComBelkadanKeystone_CompletionServer appendCompletionsForQueryString:query toArray:results headers:useHeaders];
		
		if (indexRef && *indexRef == NSNotFound && [self startsWithFirstItemSelected]) {
			ComBelkadanKeystone_FakeCompletionItem *item = [ComBelkadanKeystone_CompletionServer autocompleteForQueryString:query];
			if (item) *indexRef = [results indexOfObject:item];
		}
	}
	
	return [results autorelease];
}

/*! Swizzle-wrapped to handle fake completion items (item.isSeparator) */
- (BOOL)ComBelkadanKeystone_listItemIsSeparator:(ComBelkadanKeystone_FakeCompletionItem *)item {
	if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		return item.isSeparator;
		
	} else {
		return [self ComBelkadanKeystone_listItemIsSeparator:item];
	}
}

/*!
 * Swizzle-wrapped to handle fake completion items. Items are selectable if they
 * are not headers or separators.
 */
- (BOOL)ComBelkadanKeystone_listItemIsSelectable:(ComBelkadanKeystone_FakeCompletionItem *)item {
	if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		return !(item.isHeader || item.isSeparator);
		
	} else {
		return [self ComBelkadanKeystone_listItemIsSelectable:item];
	}
}

- (BOOL)ComBelkadanKeystone_listItemIsChecked:(ComBelkadanKeystone_FakeCompletionItem *)item {
	if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		return NO; // no check marks on Keystone completion items
		
	} else {
		return [self ComBelkadanKeystone_listItemIsChecked:item];
	}
}


/*!
 * Swizzle-wrapped to handle fake completion items. Updates the location bar to
 * show the currently highlighted completion item.
 */
- (void)ComBelkadanKeystone_reflectSelectedListItem {
	ComBelkadanKeystone_FakeCompletionItem *item = [self selectedListItem];
	if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		NSInteger selectIndex = -1;
		NSString *replacement = [item reflectedStringForQueryString:[self queryString] withSelectionFrom:&selectIndex];
		[self replaceSourceFieldCharactersInRange:NSMakeRange(0, [[self sourceFieldString] length]) withString:replacement selectingFromIndex:selectIndex];
 
	} else {
		[self ComBelkadanKeystone_reflectSelectedListItem];
	}
}

/*!
 * Swizzle-wrapped to handle fake completion items. Updates the location bar to
 * the final destination.
 */
- (BOOL)ComBelkadanKeystone_activateSelectedListItem {
	ComBelkadanKeystone_FakeCompletionItem *item = [self selectedListItem];
	if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		[self setSourceFieldString:[item urlStringForQueryString:[self queryString]]];
		return NO;
 
	} else {
		return [self ComBelkadanKeystone_activateSelectedListItem];
	}
}

/*!
 * Swizzle-wrapped to handle fake completion items. Returns the selected item's
 * name or preview URL, using the default attributes for the string.
 */
- (NSAttributedString *)ComBelkadanKeystone_displayedStringForListItem:(id)item column:(NSUInteger)col row:(NSUInteger)row {
	if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		NSString *value;
		if (col == 1) {
			value = [item previewURLStringForQueryString:[self queryString]] ?: @"";
		} else {
			value = [item nameForQueryString:[self queryString]];
		}
		
		return [[[NSAttributedString alloc] initWithString:value attributes:[self attributesForListItem:item column:col row:row forceDisabledColor:NO]] autorelease];
	} else {
		return [self ComBelkadanKeystone_displayedStringForListItem:item column:col row:row];
	}
}

/*!
 * Handles the behavior for canceling completions using Escape, as well as
 * sending completions where the pop-up wasn't open but the user still wanted one.
 */
- (BOOL)ComBelkadanKeystone_doSourceFieldCommandBySelector:(SEL)command {
	if (command == @selector(cancelOperation:) && [self respondsToSelector:@selector(_sourceField)]) {
		// only on Safari 4.0.3 -- earlier versions get this right already and this screws it up
		// desired cancel behavior: one cancel closes completion window, two resets location bar
		NSString *query = [self queryString];
		NSUInteger queryLength = [query length];
		
		if (queryLength > 0) {
			NSTextField *sourceField = [self _sourceField];
			NSString *value = [[sourceField stringValue] copy];
			
			if (![value hasPrefix:query]) queryLength = 0;
			
			[sourceField setStringValue:@""];
			[self sourceFieldTextDidChange];
			[sourceField setStringValue:value];
			[[sourceField currentEditor] setSelectedRange:NSMakeRange(queryLength, [value length] - queryLength)];	
			
			[value release];
			return YES;
		}
	} else if (command == @selector(insertNewline:)) {
		BOOL result = [self ComBelkadanKeystone_doSourceFieldCommandBySelector:command];
		NSString *query = [self sourceFieldString];
		
		ComBelkadanKeystone_FakeCompletionItem *item = [ComBelkadanKeystone_CompletionServer autocompleteForQueryString:query];
		if (item) {
			query = [query copy];

			// this closes the completions pop-up
			[self setSourceFieldString:@""];
			[self sourceFieldTextDidChange];
		
			[self setSourceFieldString:[item urlStringForQueryString:query]];
			[query release];
		}
		
		return result;
	}
	
	return [self ComBelkadanKeystone_doSourceFieldCommandBySelector:command];
}

/*!
 * Convenience method to tell if the source field is currently being edited.
 */
- (BOOL)ComBelkadanKeystone_isEditing {
	NSTextField *view = (NSTextField *)[self deepestViewContainingSourceField];
	if (![view respondsToSelector:@selector(currentEditor)]) {
		if ([self respondsToSelector:@selector(_sourceField)]) {
			view = [self _sourceField];
		} else {
			view = nil;
		}
	}

	return [NSApp keyWindow] == [view window] && [view currentEditor] != nil && [[self sourceFieldString] isEqual:[self queryString]];
}

/*!
 * In Safari 4.0.3 the completion list always acts like a menu, and this method
 * has been removed. We insert this method if necessary.
 */
- (BOOL)completionListActsLikeMenu { return YES; }
@end


