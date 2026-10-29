import Foundation
import Testing

@testable import SmartTubeIOS
@testable import SmartTubeIOSCore

@Suite("tvOS YouTube-like sidebar destinations")
struct TVOSSidebarDestinationTests {

    @Test("rail lists Search through Movies plus Settings in YouTube order")
    func destinationOrder() {
        #expect(
            TVOSSidebarDestination.allCases.map(\.rawValue) == [
                "search", "home", "subscriptions", "library", "news", "podcasts",
                "gaming", "live", "music", "sports", "movies", "settings",
            ])
    }

    @Test("Podcasts and Movies are listed but marked unavailable")
    func stubsAreUnavailable() {
        #expect(!TVOSSidebarDestination.podcasts.isAvailable)
        #expect(!TVOSSidebarDestination.movies.isAvailable)
        #expect(TVOSSidebarDestination.home.isAvailable)
        #expect(TVOSSidebarDestination.news.isAvailable)
        #expect(TVOSSidebarDestination.library.isAvailable)
    }

    @Test("category items map onto existing browse sections")
    func browseSectionMapping() {
        #expect(TVOSSidebarDestination.home.browseSectionType == .home)
        #expect(TVOSSidebarDestination.subscriptions.browseSectionType == .subscriptions)
        #expect(TVOSSidebarDestination.news.browseSectionType == .news)
        #expect(TVOSSidebarDestination.gaming.browseSectionType == .gaming)
        #expect(TVOSSidebarDestination.live.browseSectionType == .live)
        #expect(TVOSSidebarDestination.music.browseSectionType == .music)
        #expect(TVOSSidebarDestination.sports.browseSectionType == .sports)
        #expect(TVOSSidebarDestination.search.browseSectionType == nil)
        #expect(TVOSSidebarDestination.library.browseSectionType == nil)
        #expect(TVOSSidebarDestination.podcasts.browseSectionType == nil)
        #expect(TVOSSidebarDestination.movies.browseSectionType == nil)
        #expect(TVOSSidebarDestination.settings.browseSectionType == nil)
    }

    @Test("accessibility identifiers are stable per destination")
    func accessibilityIdentifiers() {
        #expect(TVOSSidebarDestination.home.accessibilityIdentifier == "tv.sidebar.home")
        #expect(TVOSSidebarDestination.search.accessibilityIdentifier == "tv.sidebar.search")
    }

    @Test("Settings sits below the primary rail items")
    func settingsIsNotInPrimaryItems() {
        #expect(!TVOSSidebarDestination.primaryItems.contains(.settings))
        #expect(TVOSSidebarDestination.primaryItems.last == .movies)
    }

    @Test("packed rail fits Apple TV 1080p without overlapping rows")
    func packedHeightFits1080p() {
        #expect(TVOSSidebarMetrics.rowHeight < 40)
        #expect(TVOSSidebarMetrics.iconSize <= TVOSSidebarMetrics.rowContentHeight)
        #expect(TVOSSidebarMetrics.labelFontSize <= 22)
        #expect(TVOSSidebarMetrics.minRowSpacing >= 6)
        #expect(TVOSSidebarMetrics.fitsAppleTV1080)
        #expect(
            TVOSSidebarMetrics.packedHeight
                <= TVOSSidebarMetrics.appleTV1080Height
                - TVOSSidebarMetrics.appleTV1080VerticalSafeBudget)
    }
}
