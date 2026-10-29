import Foundation

/// YouTube-TV-like in-player chrome for Apple TV 1080p (1920×1080 points).
///
/// Bottom transport is denser than the first chrome pass (88/72/64 pt glyphs).
/// Options / quality open as an opaque **right-side drawer** over fullscreen
/// dimmed video, not a letterboxed card and not a full-width bottom strip.
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
    static let progressThumbFocused: CGFloat = 20
    static let progressTrackHeight: CGFloat = 4
    static let progressTrackHeightFocused: CGFloat = 8
    static let progressHorizontalPad: CGFloat = 28
    static let progressTooltipHeight: CGFloat = 24
    static let progressTrackRowHeight: CGFloat = 22
    static let captionsBottomWhenControlsVisible: CGFloat = 176

    /// Legacy first-pass sizes; new chrome must stay strictly smaller.
    static let legacyPlayPauseSize: CGFloat = 88
    static let legacySeekSize: CGFloat = 72
    static let legacyActionGlyphSize: CGFloat = 64

    // MARK: Settings / options panel

    /// Right drawer over fullscreen video — not a letterboxed card, not a bottom strip.
    /// ~19% of 1080p width so the picture stays visible on the left.
    static let settingsPanelWidth: CGFloat = 360
    static let settingsPanelMaxScreenFraction: CGFloat = 0.22
    static let settingsPanelBackgroundOpacity: CGFloat = 0.96
    static let settingsPanelEdgeWidth: CGFloat = 1
    static let settingsPanelEdgeOpacity: CGFloat = 0.22
    static let settingsScrimOpacity: CGFloat = 0.4

    static let settingsTitleFontSize: CGFloat = 22
    static let settingsSubtitleFontSize: CGFloat = 14
    static let settingsRowFontSize: CGFloat = 18
    static let settingsRowCaptionFontSize: CGFloat = 13
    static let settingsRowHorizontalPadding: CGFloat = 16
    static let settingsRowVerticalPadding: CGFloat = 8
    static let settingsTitleTopPadding: CGFloat = 18
    static let settingsTitleBottomPadding: CGFloat = 10
    static let settingsRowCornerRadius: CGFloat = 8
    static let settingsRowFocusOpacity: CGFloat = 0.18

    static var settingsPanelFitsRightThird: Bool {
        settingsPanelWidth <= appleTV1080Width * settingsPanelMaxScreenFraction
    }

    static var settingsDrawerIsDense: Bool {
        settingsTitleFontSize <= 24
            && settingsRowFontSize <= 20
            && settingsRowVerticalPadding <= 10
            && settingsPanelBackgroundOpacity >= 0.94
            && settingsPanelEdgeWidth >= 1
            && settingsPanelWidth <= 380
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
