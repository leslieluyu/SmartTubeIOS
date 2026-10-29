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

/// Compact rail geometry so every destination stays readable without overlapping
/// on Apple TV 1080p (1920×1080). Semantic SwiftUI fonts are much larger on
/// tvOS (`.title2` ≈ 57pt) and were colliding in the icon stack.
enum TVOSSidebarMetrics {
    static let collapsedWidth: CGFloat = 56
    static let expandedWidth: CGFloat = 228
    static let iconSize: CGFloat = 18
    static let labelFontSize: CGFloat = 20
    static let rowContentHeight: CGFloat = 24
    static let rowVerticalPadding: CGFloat = 3
    static let rowHorizontalPadding: CGFloat = 6
    static let iconLabelSpacing: CGFloat = 10
    static let minRowSpacing: CGFloat = 8
    static let railVerticalPadding: CGFloat = 10
    static let railHorizontalPaddingCollapsed: CGFloat = 6
    static let railHorizontalPaddingExpanded: CGFloat = 10
    static let cornerRadius: CGFloat = 8
    static let appleTV1080Height: CGFloat = 1080
    /// Overscan / safe-area budget on the 1080p Apple TV simulator.
    static let appleTV1080VerticalSafeBudget: CGFloat = 80

    static var rowHeight: CGFloat {
        rowContentHeight + rowVerticalPadding * 2
    }

    /// Minimum height of the full destination list (no extra flexible space).
    static var packedHeight: CGFloat {
        let count = CGFloat(TVOSSidebarDestination.allCases.count)
        let gaps = max(0, count - 1)
        return count * rowHeight + gaps * minRowSpacing + railVerticalPadding * 2
    }

    static var fitsAppleTV1080: Bool {
        packedHeight <= appleTV1080Height - appleTV1080VerticalSafeBudget
    }
}
