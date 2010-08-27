#import <Appkit/NSTextFieldCell.h>

@interface TextCell : NSTextFieldCell
{
    BOOL _highlightsWithITunesStyleGradient;
    BOOL _suppressDefaultSelectionHighlight;
    NSString *_truncationAlternateString;
    NSString *_secondTruncationAlternateString;
    CGFloat _leftMargin;
    CGFloat _rightMargin;
    NSFont *_baselineFont;
}

+ (TextCell *)updateCellForColumn:(NSTableColumn *)column inView:(NSTableView *)view;

// Note the odd naming on this method.
- (void)suppressDefaultSelectionHighlight:(BOOL)shouldSuppress;
- (BOOL)_usingAlternateHighlightColorWithFrame:(NSRect)frame inView:(NSView *)controlView;

- (void)setHighlightsWithITunesStyleGradient:(BOOL)useITunesGradient;
- (BOOL)highlightsWithITunesStyleGradient;

- (void)setTextColorForEnabledState;

- (NSFont *)baselineFont;
- (void)setBaselineFont:(NSFont *)font;

- (CGFloat)leftMargin;
- (CGFloat)rightMargin;
- (void)setLeftMargin:(CGFloat)margin;
- (void)setRightMargin:(CGFloat)margin;

- (void)setTruncationAlternateString:(NSString *)newString;
- (NSString *)truncationAlternateString;

- (void)setSecondTruncationAlternateString:(NSString *)newString;
- (NSString *)secondTruncationAlternateString;

@end