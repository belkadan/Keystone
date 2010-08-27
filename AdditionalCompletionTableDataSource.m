#import "AdditionalCompletionTableDataSource.h"
#import "CompletionWindow.h"
#import "CompletionListTableView.h"
#import "TextCell.h"

@implementation ComBelkadanKeystone_AdditionalCompletionTableDataSource
@synthesize delegate;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return 6;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return @"Hello!";
}

- (BOOL) tableView:(NSTableView *)tableView isHeaderRow:(NSInteger)row {
	return row%4 == 0;
}

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsSeparator:(NSInteger)row {
	return (row)%3 == 0;
}

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsChecked:(NSInteger)row {
	return NO;
}

- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowSpansAllColumns:(NSInteger)row {
	return [self tableView:tableView isHeaderRow:row];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	return ![self completionListTableView:(CompletionListTableView*)tableView rowIsSeparator:row] &&
	       ![self tableView:tableView isHeaderRow:row];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self.delegate ComBelkadanKeystone_completionItemSelected:nil];
}

- (void)completionListTableView:(CompletionListTableView *)tableView mouseUpInRow:(NSInteger)row {
	[self.delegate ComBelkadanKeystone_completionItemChosen:nil];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(TextCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([@"title" isEqual:[tableColumn identifier]]) {
		if ([self tableView:tableView isHeaderRow:row]) {
			[cell setLeftMargin:4];
			[cell setEnabled:NO];
			[cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		} else {
			[cell setLeftMargin:14];
			[cell setEnabled:YES];
			[cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
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
	[super dealloc];
}

- (NSWindow *)window {
	if (!window) {
		window = [[CompletionWindow alloc] initWithContentRect:NSMakeRect(300, 700, 800, 100) styleMask:0 backing:NSBackingStoreBuffered defer:NO];
		[window setDelegate:self];

		[window setCornersAreRounded:YES];
		[window setBackgroundColor:[NSColor clearColor]];
		[window setAcceptsMouseMovedEvents:YES];

		NSView *contentView = [window contentView];
		NSScrollView *scrollView = (NSScrollView *)[self view];
		[scrollView setFrame:NSInsetRect([contentView bounds], 0, [window cornerRadius])];
		[contentView addSubview:scrollView];
		
		[table setActsLikeMenu:YES];

		TextCell *titleCell = [[table tableColumnWithIdentifier:@"title"] dataCell];
		[titleCell suppressDefaultSelectionHighlight:YES];

		TextCell *urlCell = [[table tableColumnWithIdentifier:@"url"] dataCell];
		[urlCell suppressDefaultSelectionHighlight:YES];
		[urlCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		[urlCell setBaselineFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	}
	return window;
}

- (void)showWindowForField:(NSView *)field {
	static const CGFloat kSpaceBetweenFieldAndCompletions = 2; // px

	NSRect fieldRect = [field convertRectToBase:[field bounds]];

	(void)[self window]; // force load

	NSRect frame = [window frame];
	frame.size.width = fieldRect.size.width;
	frame.origin = [[field window] convertBaseToScreen:fieldRect.origin];
	frame.origin.y -= frame.size.height + kSpaceBetweenFieldAndCompletions;
	[window setFrame:frame display:YES];
	
	[window orderFront:nil];
}

- (void)updateQuery:(NSString *)query {
	(void)[self window]; // force load
	[table reloadData];

	NSInteger rowCount = [table numberOfRows];
	if (rowCount != 0) {
		// Select the first row.
		[table deselectAll:nil];
		[self moveDown:nil];
	}

	NSSize tableSize = [table convertSizeToBase:[table bounds].size];
	NSRect frame = [window frame];
	frame.size.height = tableSize.height + 2 * [window cornerRadius];
	[window setFrame:frame display:YES];
}

- (BOOL)isActive {
	return [self isVisible] && [table selectedRow] != -1;
}

- (BOOL)isVisible {
	// This is deliberately /not/ using self.window; if the window is nil, it's not active.
	return [window isVisible];
}

@end
