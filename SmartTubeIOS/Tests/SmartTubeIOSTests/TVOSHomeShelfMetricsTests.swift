import Foundation
import Testing

@testable import SmartTubeIOS
@testable import SmartTubeIOSCore

@Suite("tvOS YouTube-like home shelf density")
struct TVOSHomeShelfMetricsTests {

    @Test("Recommended cards are ~2.5 across a 1080p content row")
    func recommendedDensityOn1080p() {
        let width = TVOSHomeShelfMetrics.recommendedCardWidth1080
        let occupied =
            TVOSHomeShelfMetrics.rowHorizontalPadding
            + 2.5 * width
            + 2 * TVOSHomeShelfMetrics.cardSpacing
        #expect(abs(occupied - TVOSHomeShelfMetrics.appleTV1080ContentWidth) < 1)
        #expect(width >= 650 && width <= 780)
        let height = width * 9 / 16
        #expect(height >= 360 && height <= 440)
    }

    @Test("lower shelves are ~3.5 across and smaller than Recommended")
    func standardDensityOn1080p() {
        let recommended = TVOSHomeShelfMetrics.recommendedCardWidth1080
        let shelf = TVOSHomeShelfMetrics.standardCardWidth1080
        #expect(shelf < recommended)
        #expect(shelf >= 430 && shelf <= 560)
        let occupied =
            TVOSHomeShelfMetrics.rowHorizontalPadding
            + 3.5 * shelf
            + 3 * TVOSHomeShelfMetrics.cardSpacing
        #expect(abs(occupied - TVOSHomeShelfMetrics.appleTV1080ContentWidth) < 1)
    }

    @Test("4K point width uses the same 2.5 density")
    func densityIndependentOfPixelScale() {
        // Apple TV 4K still reports 1920×1080 points, so the 1080p width applies.
        #expect(TVOSHomeShelfMetrics.recommendedVisibleCards == 2.5)
        #expect(TVOSHomeShelfMetrics.standardVisibleCards == 3.5)
        #expect(TVOSVideoCardStyle.recommended.focusScale > 1)
        #expect(TVOSVideoCardStyle.recommended.focusScale < TVOSVideoCardStyle.feed.focusScale)
    }

    @Test("quality badges keep 4K/HDR and drop unrelated labels")
    func qualityBadgeFilter() {
        let video = Video(
            id: "abc12_AAAAA",
            title: "Earth",
            channelTitle: "Ch",
            badges: ["4K", "HDR", "New", "4K", "Members"]
        )
        #expect(video.qualityBadgeLabels == ["4K", "HDR"])
        let none = Video(id: "def12_BBBBB", title: "T", channelTitle: "Ch", badges: ["New"])
        #expect(none.qualityBadgeLabels.isEmpty)
    }
}
