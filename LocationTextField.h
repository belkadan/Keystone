#import <AppKit/AppKit.h>

@class SpinningProgressIndicator, WebBookmark;

@interface LocationTextField : NSTextField <NSAnimationDelegate>
{
    NSImage *_siteIconImage;
    NSImage *_rssButtonImage;
    NSImage *_rssButtonHighlightedImage;
    SpinningProgressIndicator *_spinningProgressIndicator;
    BOOL _showPrivateBrowsingButton;
    BOOL _showStopReloadButton;
    BOOL _showReaderButton;
    BOOL _showRSSButton;
    BOOL _stopReloadButtonIsHighlighted;
    BOOL _privateBrowsingButtonIsHighlighted;
    BOOL _readerButtonIsHighlighted;
    BOOL _rssButtonIsHighlighted;
    BOOL _inTextDidEndEditing;
    BOOL _becomingFirstResponder;
    BOOL _settingStringValue;
    BOOL _updatingTruncation;
    BOOL _leftCapIsRounded;
    NSSize _leftCapSize;
    NSSize _rightCapSize;
    NSRect _siteIconFrame;
    NSSize _stopReloadButtonSize;
    NSSize _rssButtonSize;
    NSString *_originalString;
    NSString *_detailString;
    NSString *_pageTitle;
    BOOL _showsPageTitle;
    NSString *_siteIconDescription;
    NSString *_readerButtonDescription;
    NSString *_rssButtonDescription;
    NSString *_middleToolTip;
    NSString *_readerButtonToolTip;
    NSString *_rssButtonToolTip;
    NSInteger _middleToolTipTag;
    NSInteger _privateBrowsingButtonToolTipTag;
    NSInteger _stopReloadButtonToolTipTag;
    NSInteger _readerButtonToolTipTag;
    NSInteger _rssButtonToolTipTag;
    BOOL _toolTipRectanglesUpToDate;
    double _progressBarValue;
    BOOL _progressStalled;
    BOOL _mouseInside;
    BOOL _mouseMovedSinceProgressStalled;
    NSInteger _boundsTrackingRectTag;
    BOOL _stopReloadButtonEnabled;
    BOOL _stopReloadButtonIsForReader;
    BOOL _stopReloadButtonShowsStopOnReader;
    BOOL _stopReloadButtonIsForTopSites;
    BOOL _stopReloadButtonShowsStopOnTopSites;
    BOOL _needsToDisplayIcon;
    NSImage *_icon;
    WebBookmark *_draggingBookmark;
    int _readerButtonState;
    int _rssButtonState;
    BOOL _canShowEVCertificateButton;
    BOOL _evCertificateButtonIsHighlighted;
    BOOL _evCertificateButtonIsUnderMouse;
    NSString *_evCertificateTitle;
    NSString *_evCertificateButtonDescription;
    NSInteger _evCertificateButtonToolTipTag;
    NSInteger _evCertificateButtonTrackingRectTag;
}

- (id)view:(id)arg1 stringForToolTip:(NSInteger)arg2 point:(NSPoint)arg3 userData:(void *)arg4;
- (id)untruncatedStringValue;
- (id)backgroundImageForProgressIndicator:(id)arg1;

- (void)setDetailString:(NSString *)detailString;
- (void)setPageTitle:(NSString *)pageTitle;
- (BOOL)showsPageTitle;
- (void)setShowsPageTitle:(BOOL)shouldShowPageTitle;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;

- (void)markedTextDidChange;

- (id)accessibilityDescriptionForEVCertificateButton;
- (id)accessibilityDescriptionForPrivateBrowsingButton;
- (id)accessibilityDescriptionForSiteIcon;
- (id)accessibilityDescriptionForStopReloadButton;
- (id)accessibilityDescriptionForReaderButton;
- (id)accessibilityDescriptionForRSSButton;
- (id)accessibilityHelpStringForEVCertificateButton;
- (id)accessibilityHelpStringForPrivateBrowsingButton;
- (id)accessibilityHelpStringForStopReloadButton;
- (id)accessibilityHelpStringForReaderButton;
- (id)accessibilityHelpStringForRSSButton;

- (BOOL)isShowingPrivateBrowsingButton;
- (BOOL)isShowingStopReloadButton;
- (BOOL)isShowingReaderButton;
- (BOOL)isShowingRSSButton;
- (BOOL)isShowingEVCertificateButton;
- (void)performEVCertificateButtonAction;
- (void)performStopReloadButtonAction;
- (void)performPrivateBrowsingButtonAction;
- (void)performReaderButtonAction;
- (void)performRSSButtonAction;

- (NSRect)privateBrowsingButtonHitTestFrame;
- (NSRect)evCertificateButtonHitTestFrame;
- (NSRect)siteIconHitTestFrame;
- (NSRect)readerButtonHitTestFrame;
- (int)readerButtonState;
- (void)setReaderButtonState:(int)state;
- (NSRect)rssButtonHitTestFrame;
- (int)rssButtonState;
- (void)setRSSButtonState:(int)state;

- (void)setRollAmount:(float)arg1;
- (float)rollAmount;
- (void)finishRolling;

- (void)setExtendedValidationCertificateTitle:(id)arg1;
- (void)setKeyboardFocusRingNeedsDisplayInRect:(NSRect)arg1;
- (void)setCanShowExtendedValidationCertificateButton:(BOOL)arg1;
- (void)setLeftCapIsRounded:(BOOL)arg1;
- (void)setProgressBarValue:(double)arg1 stalled:(BOOL)arg2;
- (void)setShowingPrivateBrowsingButton:(BOOL)arg1;

- (void)setStopReloadButtonEnabled:(BOOL)arg1;
- (void)setStopReloadButtonShowsStopOnReader:(BOOL)arg1;
- (void)setStopReloadButtonIsForReader:(BOOL)arg1;
- (void)setStopReloadButtonShowsStopOnTopSites:(BOOL)arg1;
- (void)setStopReloadButtonIsForTopSites:(BOOL)arg1;
- (void)startRollingToString:(id)arg1 upwards:(BOOL)arg2;
- (BOOL)stopReloadButtonEnabled;
- (NSRect)stopReloadButtonHitTestFrame;
- (BOOL)stopReloadButtonShowsStop;
- (BOOL)stopReloadButtonIsForTopSites;

- (void)trackMenu:(id)arg1 inButtonWithTag:(int)arg2;

@end
