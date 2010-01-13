#import <Cocoa/Cocoa.h>

#ifndef COM_BELKADAN_KEYSTONE__PTR_STRUCT_PADDING
#define COM_BELKADAN_KEYSTONE__PTR_STRUCT_PADDING
typedef struct { void *p; } PtrStructPadding;
#endif

@class WebBookmark;
struct BookmarksController;
struct SNotification;
struct FileLocker;
struct Vector;

struct FileTime {
	int m_seconds;
	long m_nanoseconds;
};

@interface BookmarksControllerObjC : NSObject /* <FileLockerDelegate, NSMenuDelegate, SafariSyndicationDelegate, OldSpotlightDataSource> */
{
	struct BookmarksController *_controller;
	WebBookmark *_bookmarksBarCollection;
	WebBookmark *_bookmarksMenuCollection;
	NSMenu *_bookmarksMenu;
	BOOL _menuGood;
	BOOL _menuIncludesBonjour;
	BOOL _menuIncludesAddressBook;
	BOOL _menuIncludesBookmarksBar;
	BOOL _collectionsIncludeBonjour;
	BOOL _collectionsIncludeAddressBook;
	BOOL _RSSBookmarksInMenuAreSubscribed;
	BOOL _RSSBookmarksInBarAreSubscribed;
	BOOL _sendRSSUpdates;
	BOOL _RSSUpdatePending;
	struct FileLocker *_fileLocker;
	BOOL _reloading;
	BOOL _savePending;
	NSMutableSet *_parentalControlDomains;
	NSMutableSet *_pendingSpotlightCacheAdditions;
	NSMutableSet *_pendingSpotlightCacheDeletions;
	struct FileTime _bookmarksFileTimeForSpotlight;
	long long _bookmarksFileSizeForSpotlight;
	NSMenuItem *_lastBuiltInBookmarksMenuItem;
	PtrStructPadding /* struct OwnPtr<Safari::SObjCNotifier> */ _notifier;
}

+ (BookmarksControllerObjC *)sharedController;
- (id)initWithBookmarksMenu:(NSMenu *)menu;

+ (id)smallImageForBookmarkList;
+ (id)imageForBookmark:(id)fp8;
+ (id)bookmarkSourceForProxyIdentifier:(id)fp8;
+ (id)bookmarkTitleForProxyIdentifier:(id)fp8;

- (id)_standardBookmarksFilePath;

- (void)_removeAllBookmarksFromMenu;
- (void)addChildrenOfBookmark:(id)fp8 withTabLocation:(id)fp12 toMenu:(id)fp16 includeUnreadRSSCounts:(BOOL)fp20;
- (id)_addMenuItemForBookmark:(id)fp8 withTabLocation:(id)fp12 toMenu:(id)fp16 includeUnreadRSSCount:(BOOL)fp20;
- (id)addMenuItemForBookmark:(id)fp8 withTabLocation:(id)fp12 toMenu:(id)fp16 includeUnreadRSSCount:(BOOL)fp20;
- (void)goToNthFavoriteLeaf:(int)fp8;
- (void)addSubmenuForBookmarkSource:(id)fp8;
- (void)addFavoritesSubmenu;
- (void)addSpecialBookmarkSourcesToMenu;
- (void)_addBookmarksToMenu;

- (void)rememberBookmarksFileInfo;
- (BOOL)bookmarksFileHasChanged;
- (BOOL)reloadBookmarksFromFileIfChanged;
- (void)unlockFileLocker;
- (void)savePendingChanges;

- (id)persistentIdentifierForBookmark:(id)fp8;
- (id)bookmarkForPersistentIdentifier:(id)fp8;
- (id)bookmarkForNewWindowTabsPreference;

- (int)fileLocker:(id)fp8 actionForApparentlyAbandonedLock:(id)fp12 onAttempt:(int)fp16;
- (void)fileLocker:(id)fp8 lockWasStolen:(id)fp12;
- (void)tellUserThatISyncWon;
- (void)tellUserThatExternalChangePreemptedLocalChange;
- (void)savePendingChangesWhenever;
- (BOOL)savePendingChangesSoon;

- (void)_resetMenu;

- (id)_feedBookmarksWithURLString:(id)fp8 ignoreFilter:(BOOL)fp12;
- (BOOL)_feedBookmarksMightBeAffectedByNotification:(const struct SNotification *)fp8;
- (void)_receivedBookmarksChangedNotification:(const struct SNotification *)fp8;
- (void)bookmarksWereReloadedInGroup:(id)fp8;
- (void)_receivedDefaultsChangedNotification:(id)fp8;

- (void)fillWithBuiltInBookmarks;
- (void)exportBookmarks;
- (id)importBookmarksFrom:(id)fp8;
- (int)importFavoritesFrom:(id)fp8 intoBookmarksFolder:(id)fp12;
- (void)importIEFavorites;
- (id)_computeNetscapeAndMozillaBookmarksPath;
- (void)importNetscapeAndMozillaFavorites;

- (id)collectionNamed:(id)fp8;
- (id)uniqueUntitledCollectionName;

- (id)dateForImportFolderName;
- (id)uniqueImportFolderName;
- (BOOL)canImportBookmarks;
- (void)importBookmarks;

- (void)addBookmark:(id)fp8 title:(id)fp12;
- (void)addBookmarksForPagesInWhiteList:(id)fp8 thatAreNotInArray:(id)fp12;

- (id)allBookmarks;
- (id)bookmarksBarCollection;
- (id)bookmarksMenuCollection;
- (id)historyCollection;

- (BOOL)_menuContainsBookmark:(id)fp8;
- (BOOL)_favoritesContainsBookmark:(id)fp8;
- (void)_sendFavoritesChangedNotification;

- (void)insertProxyBookmarkWithIdentifier:(id)fp8 atIndex:(unsigned int)fp12;
- (void)updateBookmarkSources;
- (void)addFavoriteBookmark:(id)fp8 atIndex:(int)fp12;

- (void)_bookmarksFileChangedNotification:(id)fp8;
- (BOOL)visitFavoriteBookmarkFromKeyEvent:(id)fp8;
- (void)_subscribeInMailToRSSBookmark:(id)fp8;
- (void)_newBookmarkSheetDidEnd:(id)fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;

- (void)redisplayPage:(id)fp8;
- (void)redisplayPages:(id)fp8;

- (void)subscribe:(BOOL)fp8 toFeed:(id)fp12;
- (void)_getSubscribedRSSBookmarkTrees:(struct Vector *)fp8;
- (void)_passSubscribedBookmarksToSyndication;
- (void)setUpSyndicationDelegate;

- (BOOL)isBookmarkedURL:(id)fp8;
- (BOOL)shouldShowUnreadRSSCountsForCollection:(id)fp8;

- (void)_addLeafBookmark:(id)fp8 toSpotlightCacheArray:(id)fp12;
- (void)_addBookmark:(id)fp8 toSpotlightCacheArray:(id)fp12;
- (void)_addBookmarksFromArray:(id)fp8 toSpotlightCacheArray:(id)fp12;
- (void)_registerWithSpotlightCacheController;
- (id)itemsToAddForSpotlightDataType:(id)fp8;
- (id)itemsToDeleteForSpotlightDataType:(id)fp8;
- (id)allItemsForSpotlightDataType:(id)fp8;
- (void)resetAdditionsAndDeletionsForSpotlightDataType:(id)fp8;
- (void)updateWillBeginForSpotlightDataType:(id)fp8;
- (void)updateDidEndForSpotlightDataType:(id)fp8;

- (void)_displayNewBookmarksSheetForBookmark:(id)fp8 inWindow:(id)fp12 favoritesOnly:(BOOL)fp16 delegate:(id)fp20;
- (void)displayNewBookmarksSheetForBookmark:(id)fp8 inWindow:(id)fp12;
- (void)displayNewFavoritesSheetForBookmark:(id)fp8 inWindow:(id)fp12 delegate:(id)fp16;

- (BOOL)isChildAllowedToVisitURL:(id)fp8;

- (void)feed:(id)fp8 unreadCountChanged:(int)fp12;
- (void)bookmarkUUID:(id)fp8 unreadCountChanged:(int)fp12;
- (void)bookmarkFeed:(id)fp8;

@end
