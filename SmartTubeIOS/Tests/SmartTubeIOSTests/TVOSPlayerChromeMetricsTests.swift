import Foundation
import Testing

@testable import SmartTubeIOS

@Suite("tvOS YouTube-like player chrome density and settings panel")
struct TVOSPlayerChromeMetricsTests {

    @Test("bottom transport is denser than the first 88/72/64 pt chrome pass")
    func transportIsDenserThanLegacy() {
        #expect(TVOSPlayerChromeMetrics.transportIsDenserThanLegacyChrome)
        #expect(TVOSPlayerChromeMetrics.playPauseSize <= 56)
        #expect(TVOSPlayerChromeMetrics.seekSize <= 48)
        #expect(TVOSPlayerChromeMetrics.actionGlyphSize <= 44)
        #expect(TVOSPlayerChromeMetrics.progressThumb < 22)
        #expect(TVOSPlayerChromeMetrics.progressTrackHeight <= 4)
    }

    @Test("settings panel is a right-side drawer, not a full-width bottom strip")
    func settingsPanelIsRightDrawer() {
        #expect(TVOSPlayerChromeMetrics.settingsPanelFitsRightThird)
        #expect(TVOSPlayerChromeMetrics.settingsPanelWidth < TVOSPlayerChromeMetrics.appleTV1080Width / 2)
        #expect(TVOSPlayerChromeMetrics.settingsPanelWidth >= 360)
        #expect(TVOSPlayerChromeMetrics.settingsPanelWidth <= 480)
    }

    @Test("seek and play/pause keep enough layout space when denser")
    func transportMidXSpacingIsPositive() {
        #expect(TVOSPlayerChromeMetrics.transportControlMidXSpacing >= 60)
        #expect(TVOSPlayerChromeMetrics.transportControlMidXSpacing < 110)
    }
}

@Suite("tvOS fullscreen playback hides the left rail")
struct TVOSPlaybackPresentationTests {

    @Test("player appear covers browse; disappear restores the rail")
    @MainActor
    func sessionTogglesFullscreen() {
        let presentation = TVOSPlaybackPresentation()
        #expect(!presentation.isFullscreen)
        presentation.beginFullscreenSession()
        #expect(presentation.isFullscreen)
        presentation.endFullscreenSession()
        #expect(!presentation.isFullscreen)
    }
}
