#import "AdditionalCompletionTableDataSource.h"
#import "CompletionServer.h"
#import "FakeCompletionItem.h"

#import "CompletionWindow.h"
#import "CompletionListTableView.h"
#import "TextCell.h"

static NSString * const kTitleColumnID = @"title";
static CGFloat const kTitleFontSize = 12.0f; // pt
static CGFloat const kURLFontSize = 11.0f; // pt

@implementation ComBelkadanKeystone_AdditionalCompletionTableDataSource
@synthesize delegate, query, currentCompletions;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [currentCompletions count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [currentCompletions objectAtIndex:row];
	if ([kTitleColumnID isEqual:[tableColumn identifier]]) {
		return [item nameForQueryString:self.query];
	} else {
		return [item previewURLStringForQueryString:self.query];
	}
}

- (BOOL)tableView:(NSTableView *)tableView isHeaderRow:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [currentCompletions objectAtIndex:row];
	return item.isHeader;
}

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsSeparator:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [currentCompletions objectAtIndex:row];
	return item.isSeparator;
}

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsChecked:(NSInteger)row {
	return NO;
}

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowSpansAllColumns:(NSInteger)row {
	return [self tableView:tableView isHeaderRow:row];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [currentCompletions objectAtIndex:row];
	return !item.isSeparator && !item.isHeader;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	// WARNING: This is called manually with a nil notification.
	NSInteger row = [table selectedRow];

	ComBelkadanKeystone_FakeCompletionItem *item = nil;
	if (row != -1)
		item = [currentCompletions objectAtIndex:row];

	if ([self isVisible])
		[self.delegate ComBelkadanKeystone_completionItemSelected:item forQuery:self.query];
}

- (void)completionListTableView:(CompletionListTableView *)tableView mouseUpInRow:(NSInteger)row {
	ComBelkadanKeystone_FakeCompletionItem *item = [currentCompletions objectAtIndex:row];
	[self.delegate ComBelkadanKeystone_completionItemChosen:item forQuery:self.query];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(TextCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([kTitleColumnID isEqual:[tableColumn identifier]]) {
		if ([self tableView:tableView isHeaderRow:row]) {
			[cell setLeftMargin:6];
			[cell setEnabled:NO];
			[cell setFont:[NSFont systemFontOfSize:kURLFontSize]];
		} else {
			[cell setLeftMargin:18];
			[cell setEnabled:YES];
			[cell setFont:[NSFont systemFontOfSize:kTitleFontSize]];
		}
	}
}

#pragma mark -

- (IBAction)moveUp:(id)sender {
	NSInteger selection = [table selectedRow];
	do {
		selection -= 1;
	} while (selection >= 0 && ![self tableView:table shouldSelectRow:selection]);

	if (selection < 0) {
		// If we were at the top, deselect. This also handles the case where there's nothing selected now.
		[table deselectAll:nil];
	} else {
		// Otherwise, update the selection
		[table selectRowIndexes:[NSIndexSet indexSetWithIndex:selection] byExtendingSelection:NO];
	}
}

- (IBAction)moveDown:(id)sender {
	NSInteger selection = [table selectedRow];
	// -1 means no selection, but adding one to that will properly jump to the top of the table

	NSInteger rowCount = [table numberOfRows];
	do {
		selection += 1;
	} while (selection < rowCount && ![self tableView:table shouldSelectRow:selection]);

	if (selection < rowCount) {
		// If we weren't at the bottom, update the selection
		[table selectRowIndexes:[NSIndexSet indexSetWithIndex:selection] byExtendingSelection:NO];
	}
}

- (IBAction)cancelOperation:(id)sender {
	// This is deliberately /not/ using self.window; if the window is nil, it's not active.
	[window orderOut:sender];
	wasCancelled = YES;
}

- (IBAction)insertNewline:(id)sender {
	NSInteger selection = [table selectedRow];
	NSAssert(selection != -1, @"No item selected");
	ComBelkadanKeystone_FakeCompletionItem *item = [currentCompletions objectAtIndex:selection];
	[self.delegate ComBelkadanKeystone_completionItemChosen:item forQuery:self.query];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	if (aSelector == @selector(insertNewline:) ||
		aSelector == @selector(moveUp:)) {
		return [self isActive];
		
	} else if (aSelector == @selector(moveDown:) ||
			   aSelector == @selector(cancelOperation:)) {
		return [self isVisible];

	} else {
		return [super respondsToSelector:aSelector];
	}
}

#pragma mark -

+ (ComBelkadanKeystone_AdditionalCompletionTableDataSource *)sharedInstance {
	static ComBelkadanKeystone_AdditionalCompletionTableDataSource *sharedInstance = nil;
	if (!sharedInstance) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (id)init {
	return [self initWithNibName:@"CompletionTable" bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)dealloc {
	[window release];
	[currentCompletions release];
	[query release];
	[super dealloc];
}

- (NSWindow *)window {
	if (!window) {
		window = [[NSClassFromString(@"CompletionWindow") alloc] initWithContentRect:NSMakeRect(300, 700, 800, 100) styleMask:0 backing:NSBackingStoreBuffered defer:NO];
		[window setDelegate:self];

		[window setCornersAreRounded:YES];
		[window setBackgroundColor:[NSColor clearColor]];
		[window setAcceptsMouseMovedEvents:YES];

		NSView *contentView = [window contentView];
		NSScrollView *scrollView = (NSScrollView *)[self view];
		[scrollView setFrame:NSInsetRect([contentView bounds], 0.0f, [window cornerRadius])];
		[contentView addSubview:scrollView];
		
		[table setActsLikeMenu:YES];

		TextCell *titleCell = [[table tableColumnWithIdentifier:@"title"] dataCell];
		[titleCell suppressDefaultSelectionHighlight:YES];

		TextCell *urlCell = [[table tableColumnWithIdentifier:@"url"] dataCell];
		[urlCell suppressDefaultSelectionHighlight:YES];
		[urlCell setFont:[NSFont systemFontOfSize:kURLFontSize]];
		[urlCell setBaselineFont:[NSFont systemFontOfSize:kTitleFontSize]];
	}
	return window;
}

- (void)showWindowForField:(NSView *)field {
	if ([self.currentCompletions count] == 0)
		return;

	static const CGFloat kSpaceBetweenFieldAndCompletions = 2; // px

	NSRect fieldRect = [field convertRectToBase:[field bounds]];

	(void)[self window]; // force load

	NSRect frame = [window frame];
	frame.size.width = fieldRect.size.width;
	frame.origin = [[field window] convertBaseToScreen:fieldRect.origin];
	frame.origin.y -= frame.size.height + kSpaceBetweenFieldAndCompletions;
	[window setFrame:frame display:YES];
	
	[window orderFront:nil];
	// Select the first row.
	[table deselectAll:nil];
	[self moveDown:nil];
}

- (void)updateQuery:(NSString *)newQuery {
	if ([self.query isEqual:newQuery])
		return;
	
	self.query = newQuery;
	self.currentCompletions = [ComBelkadanKeystone_CompletionServer completionsForQueryString:newQuery headers:YES];
	wasCancelled = NO;
	
	(void)[self window]; // force load
	[table deselectAll:nil];
	[table reloadData];

	NSInteger rowCount = [self.currentCompletions count];
	if (rowCount == 0) {
		[self cancelOperation:nil];
	} else {
		// Select the first row.
		[self moveDown:nil];

		NSRect firstRowRect = [table rectOfRow:0];
		NSRect lastRowRect = [table rectOfRow:rowCount-1];
		CGFloat newHeight = (NSMaxY(lastRowRect) - NSMinY(firstRowRect));
		newHeight += 2 * [window cornerRadius];

		NSRect frame = [window frame];
		frame.origin.y -= (newHeight - frame.size.height);
		frame.size.height = newHeight;
		[window setFrame:frame display:YES];
	}
}

- (BOOL)isActive {
	return [self isVisible] && [table selectedRow] != -1;
}

- (BOOL)isVisible {
	// This is deliberately /not/ using self.window; if the window is nil, it's not active.
	return [window isVisible];
}

- (BOOL)wasCancelled {
	return wasCancelled;
}

- (void)clearCancelled {
	wasCancelled = NO;
}

@end
