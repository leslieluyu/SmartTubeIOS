import Foundation
import SmartTubeIOSCore

/// Destinations in the tvOS left navigation rail, approximating YouTube on
/// Apple TV. Unavailable items (no in-app feed) stay listed and open a stub.
enum TVOSSidebarDestination: String, CaseIterable, Identifiable, Hashable {
    case search
    case home
    case subscriptions
    case library
    case news
    case podcasts
    case gaming
    case live
    case music
    case sports
    case movies
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search: return "Search"
        case .home: return "Home"
        case .subscriptions: return "Subscriptions"
        case .library: return "Library"
        case .news: return "News"
        case .podcasts: return "Podcasts"
        case .gaming: return "Gaming"
        case .live: return "Live"
        case .music: return "Music"
        case .sports: return "Sports"
        case .movies: return "Movies"
        case .settings: return "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .search: return AppSymbol.search
        case .home: return AppSymbol.home
        case .subscriptions: return AppSymbol.subscriptions
        case .library: return AppSymbol.library
        case .news: return AppSymbol.news
        case .podcasts: return AppSymbol.podcasts
        case .gaming: return AppSymbol.gaming
        case .live: return AppSymbol.live
        case .music: return AppSymbol.music
        case .sports: return AppSymbol.sports
        case .movies: return AppSymbol.movies
        case .settings: return AppSymbol.settings
        }
    }

    /// `false` for destinations this app cannot fetch yet — the rail still
    /// shows them and the page explains they are unavailable.
    var isAvailable: Bool {
        switch self {
        case .podcasts, .movies: return false
        default: return true
        }
    }

    /// Browse chip/section this rail item maps to, when the Home feed already
    /// knows how to load that category.
    var browseSectionType: BrowseSection.SectionType? {
        switch self {
        case .home: return .home
        case .subscriptions: return .subscriptions
        case .news: return .news
        case .gaming: return .gaming
        case .live: return .live
        case .music: return .music
        case .sports: return .sports
        default: return nil
        }
    }

    var accessibilityIdentifier: String { "tv.sidebar.\(rawValue)" }

    /// Destinations above the bottom Settings slot.
    static var primaryItems: [TVOSSidebarDestination] {
        allCases.filter { $0 != .settings }
    }
}
