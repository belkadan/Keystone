#import <Cocoa/Cocoa.h>

/* generated with class-dump */
/* Safari 4.0 - 4.0.2 */
/* in 4.0.3 each class has the name "Old" prepended */

@class CompletionWindow, CompletionListTableView, WebDynamicScrollBarsView;
typedef struct { void *p; } PtrStructPadding;

@interface CompletionController : NSObject /* <NSTableViewDataSource, NSTableViewDelegate> */
{
@public
	NSWindow *_sourceWindow;
	CompletionWindow *_completionListWindow;
	CompletionListTableView *_tableView;
	WebDynamicScrollBarsView *_scrollView;
	NSString *_userTypedString;
	NSArray *_listItems;
	CGFloat _standardRowHeight;
	NSInteger _selectedListItemIndex;
	BOOL _selectionIsStale;
	BOOL _blockCompletion;
	BOOL _blockReflectSelection;
	BOOL _ignoreTextDidChange;
	BOOL _listIsVisible;
	BOOL _showListForSingleOverride;
	BOOL _replaceEntireField;
	BOOL _inProgrammaticChange;
}

+ (void)setAllCompletionsBlocked:(BOOL)blocked;
- (id)initWithUserTypedString:(NSString *)string inWindow:(NSWindow *)window;

- (WebDynamicScrollBarsView *)scrollView;
- (NSWindow *)sourceWindow;

- (BOOL)completionListIsShowing;
- (void)completionListDidHide;
- (unsigned long)maximumNumberOfRows;
- (NSRect)computeCompletionWindowFrame;
- (void)abortCompletion;

- (id)selectedListItem;
- (NSArray *)currentListItems;
- (void)reflectSelectedListItem;
- (void)reflectFinalSelectedListItem;

- (void)trackCompletionListFromMouseDown:(id)unknown;
- (NSUInteger)maxStringLength;
- (BOOL)completionListActsLikeMenu;
- (BOOL)shouldSuppressAutocomplete;
- (BOOL)currentTextChangeIsProgrammatic;
- (BOOL)string:(id)unknown fitsInColumn:(NSUInteger)col row:(NSUInteger)row;

- (NSFont *)sourceFieldFont;
- (NSView *)deepestViewContainingSourceField;
- (NSString *)sourceFieldString;
- (void)setSourceFieldString:(NSString *)newString;
- (NSRect)sourceFieldFrame;
- (NSRange)sourceFieldSelectedRange;
- (void)performSourceFieldAction;
- (void)replaceSourceFieldCharactersInRange:(NSRange)range withString:(NSString *)replacement selectingFromIndex:(NSInteger)fromIndex;

- (NSArray *)computeListItemsAndInitiallySelectedIndex:(NSUInteger *)initialIndex;
- (NSString *)queryString;
- (id)reflectedStringForHighlightedListItem:(id)item;
- (id)reflectedStringForActivatedListItem:(id)item;
- (BOOL)leavingFieldReflectsSelectedListItem;
- (NSUInteger)numberOfColumnsInCompletionList;

- (NSDictionary *)attributesForListItem:(id)item column:(NSUInteger)col row:(NSUInteger)row forceDisabledColor:(BOOL)forceDisabled;
- (NSAttributedString *)displayedStringForListItem:(id)item column:(NSUInteger)col row:(NSUInteger)row;
- (BOOL)activateSelectedListItem;

- (void)completionListDidChange:(struct CompletionListGenerator *)generator;
- (float)completionListInsetFromSourceField;

- (BOOL)listItemIsChecked:(id)item;
- (BOOL)listItemIsSelectable:(id)item;
- (BOOL)listItemIsSeparator:(id)item;

- (BOOL)returnPerformsActionWhenShowingList;
- (NSUInteger)scrollersSize;

- (NSFont *)fontForListItem:(id)item column:(NSUInteger)col;
- (NSFont *)baselineFont;
- (CGFloat)indentationForListItem:(id)item column:(NSUInteger)col;
- (BOOL)useDisabledTextColorForListItem:(id)item column:(NSUInteger)col;
- (BOOL)useSelectedTextColorForRow:(NSUInteger)row;

- (BOOL)showsListForSingleListItem;
- (NSString *)userTypedString;
- (void)userTypedStringDidChange;

- (void)performCompletionListCommandWithGenerator:(struct CompletionListGenerator *)generator commandSender:(struct CommandSender *)commandSender tag:(NSInteger)tag;
- (NSUInteger)matchCountOnCurrentPage:(struct CompletionListGenerator *)generator limit:(NSUInteger)limit;
- (BOOL)shouldIncludeFindOnPageInCompletionList:(struct CompletionListGenerator *)generator;

- (void)sourceFieldTextDidChange;
- (void)sourceFieldTextDidEndEditing;
- (BOOL)handleInsertNewline;
- (BOOL)sourceFieldIsEmpty;
- (BOOL)doSourceFieldCommandBySelector:(SEL)command;

- (id)tableView:(CompletionListTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)rowIndex;
// other usual table view data source/delegate methods omitted
- (BOOL)completionListTableView:(CompletionListTableView *)tableView rowIsSeparator:(NSInteger)row;
- (void)completionListTableView:(CompletionListTableView *)tableView mouseUpInRow:(NSInteger)row;

@end

@interface ToolbarCompletionController : CompletionController
{
	PtrStructPadding /* struct OwnPtr<Safari::CompletionListGenerator> */ _generator;
	PtrStructPadding /* struct OwnPtr<Safari::CompletionListGeneratorClientAdapter> */ _generatorClientAdapter;
	NSTextField *_sourceField;
}

- (id)initWithSourceField:(NSTextField *)sourceField;
- (struct CompletionListGenerator *)createCompletionListGenerator;
- (NSTextField *)sourceField;
- (BOOL)startsWithFirstItemSelected;

@end

@interface URLCompletionController : ToolbarCompletionController
{
}
@end
