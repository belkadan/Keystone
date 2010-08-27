#import <AppKit/NSTableView.h>

@interface CompletionListTableView : NSTableView
{
    BOOL _actsLikeMenu;
    BOOL _lastMousePositionWasOverList;
}

- (void)setActsLikeMenu:(BOOL)actsLikeMenu;
- (BOOL)actsLikeMenu;

@end
