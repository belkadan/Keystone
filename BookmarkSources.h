#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#ifndef COM_BELKADAN_KEYSTONE__PTR_STRUCT_PADDING
#define COM_BELKADAN_KEYSTONE__PTR_STRUCT_PADDING
typedef struct { void *p; } PtrStructPadding;
#endif

@class HistoryTextCache;

@protocol BookmarkSource
- (void)refreshContents;
- (BOOL)canCopyContents;
- (BOOL)canDeleteContents;
- (BOOL)deleteContentItems:(id)fp8 withParentWindow:(id)fp12 undoManager:(id)fp16;
- (BOOL)contentItemCanBeSearchResult:(id)fp8;
- (BOOL)contentItemCanHaveChildren:(id)fp8;
- (id)child:(NSUInteger)fp8 ofContentItem:(id)fp12;
- (NSUInteger)numberOfChildrenOfContentItem:(id)fp8;
- (id)parentOfContentItem:(id)fp8;
- (void)didCollapseContentItem:(id)fp8;
- (void)didExpandContentItem:(id)fp8;
- (id)contentItemsToInitiallyExpand;
- (id)contentItemsToExpandOnReload;
- (id)bookmarkFromContentItem:(id)fp8;
- (BOOL)canGoToContentItem:(id)fp8;
- (void)goToContentItem:(id)fp8 tabLocation:(id)fp12;
- (void)goToContentItemInNewWindow:(id)fp8;
- (void)goToContentItemInNewTab:(id)fp8 tabLocation:(id)fp12;
- (void)goToChildrenOfContentItemInTabs:(id)fp8 tabLocation:(id)fp12;
- (id)bookmarksFromContentItems:(id)fp8;
- (id)bookmarkSourceImage;
- (id)addressStringForContentItem:(id)fp8;
- (id)titleStringForContentItem:(id)fp8;
- (id)imageForContentItem:(id)fp8;
- (BOOL)shouldShowRSSLabelForContentItem:(id)fp8;
- (BOOL)isFilteredFromOtherSources;
- (void)addBookmarkSourceMenu:(id)fp8 withTabLocation:(id)fp12;
- (id)tabLocationForMenu:(id)fp8;
- (void)removeBookmarkSourceMenu:(id)fp8;
- (id)bookmarkSourceMenuTitle;
@end

#ifdef MAC_OS_X_VERSION_10_6
@interface BookmarkSource : NSObject <BookmarkSource, NSMenuDelegate>
#else
@interface BookmarkSource : NSObject <BookmarkSource>
#endif
{
	NSMutableSet *_updatedBookmarkSourceMenus;
	NSMutableDictionary *_tabLocationsForBookmarkSourceMenus;
}

- (void)addBookmarkSourceMenu:(id)probablyMenu withTabLocation:(id)tabLocation;
- (id)tabLocationForMenu:(id)probablyMenu;
- (void)removeBookmarkSourceMenu:(id)probablyMenu;

- (void)setAllMenusNeedRealUpdate;
- (void)setMenu:(NSMenu *)menu needsRealUpdate:(BOOL)needsUpdate;
- (BOOL)menuNeedsRealUpdate:(NSMenu *)menu;

@end

@interface GlobalHistory : BookmarkSource <NSUserInterfaceValidations /*, OldSpotlightDataSource*/>
{
	WebHistory *_webHistory;
	CFDateFormatterRef _dateFormatter;
	HistoryTextCache *_textCache;
	NSUndoManager *_undoManager;
	BOOL _performingUndoableAction;
	NSMenu *_historyMenu;
	NSUInteger _builtInHistoryMenuItemsCount;
	NSTimer *_saveToDiskTimer;
	NSUInteger _saveToDiskThread;
	CFSetRef _pendingSpotlightCacheAdditions;
	NSMutableDictionary *_fullTextOfURLsPendingSpotlightCacheAddition;
	CFSetRef _pendingSpotlightCacheDeletions;
	BOOL _deleteEntireSpotlightCache;
	PtrStructPadding /* struct OwnPtr<GlobalHistorySnapshotProtector> */ _snapshotProtector;
}

+ (NSURL *)historyURL;
+ (GlobalHistory *)sharedGlobalHistory;

- (void)setUndoManager:(NSUndoManager *)undoManager;
- (NSUndoManager *)undoManager;

- (void)cachePageTextForWebView:(id)webView;
- (id)URLStringMatchesFromCachedPageTextForString:(id)fp8;
- (id)allItemsForSpotlightDataType:(id)fp8;
- (id)itemsToAddForSpotlightDataType:(id)fp8;
- (id)itemsToDeleteForSpotlightDataType:(id)fp8;
- (void)resetAdditionsAndDeletionsForSpotlightDataType:(id)fp8;
- (void)updateDidEndForSpotlightDataType:(id)fp8;
- (void)updateWillBeginForSpotlightDataType:(id)fp8;
- (void)addMenuItemForHistoryItem:(id)fp8 toMenu:(id)fp12;
- (void)clearHistory;
- (void)confirmClearingHistory;
- (BOOL)hasAnyHistoryItems;
- (void)savePendingChangesBeforeTermination;
- (void)setHistoryAgeLimitFromPreferences;
- (void)setHistoryMenu:(id)fp8;
- (void)updateDisplayTitleForHistoryItem:(id)fp8;

- (WebHistory *)webHistory;

@end
