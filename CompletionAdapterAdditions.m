#import "CompletionAdapterAdditions.h"
#import "CompletionAdapter.h"

#import "CompletionControllerAdditions.h"
#import "CompletionHandler.h"
#import "FakeCompletionItem.h"

#import "SwizzleMacros.h"

#define KEYSTONE_PREFIX ComBelkadanKeystone_

static NSString *queryString (struct CompletionController *controller) {
	return (NSString *)controller->_str;
}

static NSMapTable *additionalResultsTable = nil;

@interface ComBelkadanKeystone_CompletionControllerObjCAdapter ()
- (NSArray *) ComBelkadanKeystone_calculateResults;
- (ComBelkadanKeystone_FakeCompletionItem *) ComBelkadanKeystone_itemForRow:(NSInteger*)rowIndex;

- (NSInteger) ComBelkadanKeystone_numberOfRowsInTableView:(NSTableView *)tableView;
- (id) ComBelkadanKeystone_tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex;
- (CGFloat) ComBelkadanKeystone_tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row;

- (BOOL) ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowIsChecked:(NSInteger)row;
- (BOOL) ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowIsSeparator:(NSInteger)row;
- (BOOL) ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowSpansAllColumns:(NSInteger)row;
- (void) ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView mouseUpInRow:(NSInteger)row;

- (void) ComBelkadanKeystone_completionListDidHide;

@end


@implementation ComBelkadanKeystone_CompletionControllerObjCAdapter
+ (void)initialize {
	if (!additionalResultsTable) {
		additionalResultsTable = [[NSMapTable mapTableWithWeakToStrongObjects] retain];

		Class fromClass = [self class];
		Class toClass = [CompletionControllerObjCAdapter class];
		
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_calculateResults);
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_itemForRow:);
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_rowForOriginalRow:);
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_resizeTable:);
		COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_reloadDataInCompletionListTableView:);

		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, numberOfRowsInTableView:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:objectValueForTableColumn:row:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:shouldShowCellExpansionForTableColumn:row:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:willDisplayCell:forTableColumn:row:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:heightOfRow:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:shouldSelectRow:);

		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableViewSelectionDidChange:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableViewSelectionIsChanging:);

		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, completionListTableView:rowIsSeparator:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, completionListTableView:rowIsChecked:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, completionListTableView:rowSpansAllColumns:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, completionListTableView:mouseUpInRow:);

		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, completionListDidHide);
		
		COPY_AND_EXCHANGE(fromClass, NSClassFromString(@"CompletionListTableView"), KEYSTONE_PREFIX, setDataSource:);
		COPY_AND_EXCHANGE(fromClass, NSClassFromString(@"CompletionListTableView"), KEYSTONE_PREFIX, reloadData);
		COPY_AND_EXCHANGE(fromClass, NSClassFromString(@"CompletionListTableView"), KEYSTONE_PREFIX, selectedRow);
		COPY_AND_EXCHANGE(fromClass, NSClassFromString(@"CompletionListTableView"), KEYSTONE_PREFIX, selectRowIndexes:byExtendingSelection:);
	}
}

#pragma mark -

- (NSArray *)ComBelkadanKeystone_calculateResults {
	NSString *query = queryString(_completionController);
	NSMutableArray *results = [NSMutableArray array];
	
	for (id <ComBelkadanKeystone_CompletionHandler> nextHandler in [ComBelkadanKeystone_URLCompletionController completionHandlers]) {
		NSArray *customCompletions = [nextHandler completionsForQueryString:query];
		
		if ([customCompletions count] > 0) {
			[results addObject:[ComBelkadanKeystone_FakeCompletionItem separatorItem]];

			NSString *title = [nextHandler headerTitle];
			if (title) {
				ComBelkadanKeystone_FakeCompletionItem *headerItem = [[ComBelkadanKeystone_SimpleCompletionItem alloc] initWithName:title URLString:nil];
				[results addObject:headerItem];
				[headerItem release];
			}
			
			[results addObjectsFromArray:customCompletions];
		}
	}

	return results;
}

- (ComBelkadanKeystone_FakeCompletionItem *)ComBelkadanKeystone_itemForRow:(NSInteger *)rowIndex {
	// Special case for "top hit" and its separator
	if (*rowIndex <= 2) {
		return nil;
	}
	
	// One of our extra completions
	NSArray *results = [additionalResultsTable objectForKey:self];
	if (*rowIndex < [results count]+2) {
		*rowIndex -= 2;
		return [results objectAtIndex:*rowIndex];
	}

	// Remaining completions
	*rowIndex -= [results count];
	return nil;
}

- (NSInteger)ComBelkadanKeystone_rowForOriginalRow:(NSInteger)originalRow {
	// Special case for "top hit" and its separator
	if (originalRow <= 2) {
		return originalRow;
	}

	return originalRow + [[additionalResultsTable objectForKey:self] count];
}

- (void)ComBelkadanKeystone_completionListDidHide {
	[additionalResultsTable removeObjectForKey:self];
	[self ComBelkadanKeystone_completionListDidHide];
}

- (void)ComBelkadanKeystone_reloadDataInCompletionListTableView:(NSTableView *)tableView {
	NSArray *additionalResults = [self ComBelkadanKeystone_calculateResults];
	[additionalResultsTable setObject:additionalResults forKey:self];
}

- (NSInteger)ComBelkadanKeystone_numberOfRowsInTableView:(NSTableView *)tableView {
	NSArray *additionalResults = [additionalResultsTable objectForKey:self];
	return [additionalResults count] + [self ComBelkadanKeystone_numberOfRowsInTableView:tableView];
}

- (void)ComBelkadanKeystone_resizeTable:(NSTableView *)tableView {
	if (![tableView window] || [[[tableView enclosingScrollView] verticalScroller] isHidden]) return;

	NSArray *additionalResults = [additionalResultsTable objectForKey:self];
	CGFloat heightDelta = [additionalResults count] * [tableView rowHeight];

	NSWindow *completionWindow = [tableView window];
	NSRect frame = [completionWindow frame];
	frame.size.height += heightDelta;
	frame.origin.y -= heightDelta;
	[completionWindow setFrame:frame display:YES];
}

- (id)ComBelkadanKeystone_tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&rowIndex];
	if (item) {
		NSString *value;
		if ([tableView columnWithIdentifier:[tableColumn identifier]] == 1) {
			value = [item previewURLStringForQueryString:queryString(_completionController)] ?: @"";
		} else {
			value = [item nameForQueryString:queryString(_completionController)];
		}
		
		return value;
	} else {
		return [self ComBelkadanKeystone_tableView:tableView objectValueForTableColumn:tableColumn row:rowIndex];
	}
}

- (void)ComBelkadanKeystone_tableViewSelectionDidChange:(NSNotification *)note {
	NSInteger row = [[note object] ComBelkadanKeystone_selectedRow];
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		;
	} else {
		[self ComBelkadanKeystone_tableViewSelectionDidChange:note];
	}
}

- (void)ComBelkadanKeystone_tableViewSelectionIsChanging:(NSNotification *)note {
	NSInteger row = [[note object] ComBelkadanKeystone_selectedRow];
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		;
	} else {
		[self ComBelkadanKeystone_tableViewSelectionIsChanging:note];
	}	
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		return NO;
	} else {
		return [self ComBelkadanKeystone_tableView:tableView shouldShowCellExpansionForTableColumn:column row:row];
	}
}

- (CGFloat)ComBelkadanKeystone_tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	return [tableView rowHeight];
}

- (void)ComBelkadanKeystone_tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		if (item.isHeader) {
			[self ComBelkadanKeystone_tableView:tableView willDisplayCell:cell forTableColumn:column row:0];
		} else {
			[self ComBelkadanKeystone_tableView:tableView willDisplayCell:cell forTableColumn:column row:1];
		}
	} else {
		[self ComBelkadanKeystone_tableView:tableView willDisplayCell:cell forTableColumn:column row:row];
	}
}

- (BOOL)ComBelkadanKeystone_tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		return !(item.isSeparator || item.isHeader);
	} else {
		return [self ComBelkadanKeystone_tableView:tableView shouldSelectRow:row];
	}
}

- (BOOL)ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowIsSeparator:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		return item.isSeparator;
	} else {
		return [self ComBelkadanKeystone_completionListTableView:tableView rowIsSeparator:row];
	}
}

- (BOOL)ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowIsChecked:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		return NO;
	} else {
		return [self ComBelkadanKeystone_completionListTableView:tableView rowIsChecked:row];
	}
}

- (BOOL)ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowSpansAllColumns:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		return item.isHeader || item.isSeparator;
	} else {
		return [self ComBelkadanKeystone_completionListTableView:tableView rowSpansAllColumns:row];
	}
}

- (void)ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView mouseUpInRow:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_itemForRow:&row];
	if (item) {
		[self ComBelkadanKeystone_completionListTableView:tableView mouseUpInRow:row];
	} else {
		[self ComBelkadanKeystone_completionListTableView:tableView mouseUpInRow:row];
	}
}

#pragma mark -

- (void)ComBelkadanKeystone_setDataSource:(id <NSTableViewDataSource>)dataSource {
	[dataSource ComBelkadanKeystone_reloadDataInCompletionListTableView:self];
	[self ComBelkadanKeystone_setDataSource:dataSource];
	//[dataSource ComBelkadanKeystone_resizeTable:self];
}

- (void)ComBelkadanKeystone_reloadData {
	[[self dataSource] ComBelkadanKeystone_reloadDataInCompletionListTableView:self];
	[self ComBelkadanKeystone_reloadData];
}

- (NSInteger)ComBelkadanKeystone_selectedRow {
	NSInteger selection = [self ComBelkadanKeystone_selectedRow];
	[[self dataSource] ComBelkadanKeystone_itemForRow:&selection];
	return selection;
}

- (void)ComBelkadanKeystone_selectRowIndexes:(NSIndexSet *)rows byExtendingSelection:(BOOL)extend {
	//row = [[self dataSource] ComBelkadanKeystone_rowForOriginalRow:row];
	[self ComBelkadanKeystone_selectRowIndexes:rows byExtendingSelection:extend];
}

@end