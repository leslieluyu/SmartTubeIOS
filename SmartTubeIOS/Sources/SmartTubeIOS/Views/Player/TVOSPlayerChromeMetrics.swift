import Foundation

/// YouTube-TV-like in-player chrome for Apple TV 1080p (1920×1080 points).
///
/// Bottom transport is denser than the first chrome pass (88/72/64 pt glyphs).
/// Options / quality open as a **right-side** panel, not a full-width bottom strip.
/// Software highlight sizes stay here so 4K Select restore (`TVOSPlayerFocusPolicy`)
/// is unchanged — native focus is still not placed on these controls.
enum TVOSPlayerChromeMetrics {
    static let appleTV1080Width: CGFloat = 1920

    // MARK: Bottom bar

    static let horizontalPadding: CGFloat = 36
    static let bottomPadding: CGFloat = 22
    static let topPadding: CGFloat = 10
    static let infoSpacing: CGFloat = 8
    static let transportSpacing: CGFloat = 20
    static let actionSpacing: CGFloat = 8
    static let titleFontSize: CGFloat = 28
    static let descriptionFontSize: CGFloat = 18
    static let subscribeHorizontalPadding: CGFloat = 16
    static let subscribeVerticalPadding: CGFloat = 6

    static let playPauseSize: CGFloat = 52
    static let playPauseIconSize: CGFloat = 26
    static let playPauseHighlightScale: CGFloat = 1.18
    static let seekSize: CGFloat = 44
    static let seekIconSize: CGFloat = 20
    static let seekHighlightScale: CGFloat = 1.14
    static let skipSize: CGFloat = 40
    static let skipHighlightScale: CGFloat = 1.12
    static let actionGlyphSize: CGFloat = 40
    static let actionGlyphHighlightScale: CGFloat = 1.14
    static let actionGlyphIconSize: CGFloat = 18

    static let progressThumb: CGFloat = 14
    static let progressTrackHeight: CGFloat = 4
    static let progressHorizontalPad: CGFloat = 28
    static let progressTooltipHeight: CGFloat = 24
    static let progressTrackRowHeight: CGFloat = 22
    static let captionsBottomWhenControlsVisible: CGFloat = 176

    /// Legacy first-pass sizes; new chrome must stay strictly smaller.
    static let legacyPlayPauseSize: CGFloat = 88
    static let legacySeekSize: CGFloat = 72
    static let legacyActionGlyphSize: CGFloat = 64

    // MARK: Settings / options panel

    /// ~22% of 1080p width — a right drawer, not a bottom strip.
    static let settingsPanelWidth: CGFloat = 420
    static let settingsPanelMaxScreenFraction: CGFloat = 0.28
    static let settingsPanelBackgroundOpacity: CGFloat = 0.92

    static var settingsPanelFitsRightThird: Bool {
        settingsPanelWidth <= appleTV1080Width * settingsPanelMaxScreenFraction
    }

    static var transportIsDenserThanLegacyChrome: Bool {
        playPauseSize < legacyPlayPauseSize
            && seekSize < legacySeekSize
            && actionGlyphSize < legacyActionGlyphSize
    }

    /// Layout-space between seek and play/pause midpoints (highlight scale is visual only).
    static var transportControlMidXSpacing: CGFloat {
        seekSize / 2 + transportSpacing + playPauseSize / 2
    }
}
