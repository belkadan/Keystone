#import <Cocoa/Cocoa.h>

@interface NSPreferences : NSObject
{
    NSWindow *_preferencesPanel;
    NSBox *_preferenceBox;
    NSMatrix *_moduleMatrix;
    NSButtonCell *_okButton;
    NSButtonCell *_cancelButton;
    NSButtonCell *_applyButton;
    NSMutableArray *_preferenceTitles;
    NSMutableArray *_preferenceModules;
    NSMutableDictionary *_masterPreferenceViews;
    NSMutableDictionary *_currentSessionPreferenceViews;
    NSBox *_originalContentView;
    BOOL _isModal;
    float _constrainedWidth;
    id _currentModule;
    void *_reserved;
}

+ (id)sharedPreferences;
+ (void)setDefaultPreferencesClass:(Class)preferencesClass;
+ (Class)defaultPreferencesClass;

- (void)addPreferenceNamed:(NSString *)name owner:(id)owner;

- (void)_setupToolbar;
- (void)_setupUI;
- (NSSize)preferencesContentSize;

- (void)showPreferencesPanel;
- (void)showPreferencesPanelForOwner:(id)owner;
- (NSInteger)showModalPreferencesPanelForOwner:(id)owner;
- (NSInteger)showModalPreferencesPanel;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)apply:(id)sender;

- (void)_selectModuleOwner:(id)owner;

- (NSString *)windowTitle;
- (void)confirmCloseSheetIsDone:(id)fp8 returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (BOOL)windowShouldClose:(NSWindow *)window;
- (void)windowDidResize:(NSNotification *)note;
- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)size;

- (BOOL)usesButtons;

- (NSString *)_itemIdentifierForModule:(id)module;

- (void)toolbarItemClicked:(id)sender;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInserted;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

@end

@protocol NSPreferencesModule
- (NSView *)viewForPreferenceNamed:(NSString *)name;
- (NSImage *)imageForPreferenceNamed:(NSString *)name;
- (BOOL)hasChangesPending;
- (void)saveChanges;
- (void)willBeDisplayed;
- (void)initializeFromDefaults;
- (void)didChange;
- (void)moduleWillBeRemoved;
- (void)moduleWasInstalled;
- (BOOL)moduleCanBeRemoved;
- (BOOL)preferencesWindowShouldClose;
@end

@interface NSPreferencesModule : NSObject <NSPreferencesModule>
{
    IBOutlet NSBox *preferencesView;
    NSSize _minSize;
    BOOL _hasChanges;
    void *_reserved;
}

+ (id)sharedInstance;
- (NSString *)preferencesNibName;
- (void)setPreferencesView:(NSView *)view;
- (NSString *)titleForIdentifier:(NSString *)identifier;
- (NSSize)minSize;
- (void)setMinSize:(NSSize)minSize;
- (BOOL)isResizable;

@end
