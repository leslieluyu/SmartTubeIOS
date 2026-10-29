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

/// Medium rail geometry for Apple TV 1080p (1920×1080).
/// Smaller than tvOS `.title2` / `.headline` (those overlapped); larger than
/// the 18/20pt tighten pass (that looked sparse). Icons 28–32pt, labels 24–28pt.
enum TVOSSidebarMetrics {
    static let collapsedWidth: CGFloat = 72
    static let expandedWidth: CGFloat = 272
    static let iconSize: CGFloat = 30
    static let labelFontSize: CGFloat = 26
    static let rowContentHeight: CGFloat = 34
    static let rowVerticalPadding: CGFloat = 8
    static let rowHorizontalPadding: CGFloat = 12
    static let iconLabelSpacing: CGFloat = 14
    static let rowSpacing: CGFloat = 8
    static let railVerticalPadding: CGFloat = 18
    static let railHorizontalPaddingCollapsed: CGFloat = 8
    static let railHorizontalPaddingExpanded: CGFloat = 12
    static let cornerRadius: CGFloat = 10
    static let selectedPillOpacity: CGFloat = 0.22
    static let appleTV1080Height: CGFloat = 1080
    /// Overscan / safe-area budget on the 1080p Apple TV simulator.
    static let appleTV1080VerticalSafeBudget: CGFloat = 80

    static var rowHeight: CGFloat {
        rowContentHeight + rowVerticalPadding * 2
    }

    /// Height of the destination list with fixed row spacing (Settings gap
    /// collapsed to `rowSpacing`). Extra screen height sits below Movies.
    static var packedHeight: CGFloat {
        let count = CGFloat(TVOSSidebarDestination.allCases.count)
        let gaps = max(0, count - 1)
        return count * rowHeight + gaps * rowSpacing + railVerticalPadding * 2
    }

    static var fitsAppleTV1080: Bool {
        packedHeight <= appleTV1080Height - appleTV1080VerticalSafeBudget
    }
}

/// Visual state for one rail row. Focus always wins so the current page and
/// the focused destination cannot both show the strong white pill.
enum TVOSSidebarRowChrome: Equatable {
    case idle
    case selected
    case focused
}

enum TVOSSidebarHighlightPolicy {
    static func chrome(isSelected: Bool, isFocused: Bool) -> TVOSSidebarRowChrome {
        if isFocused { return .focused }
        if isSelected { return .selected }
        return .idle
    }
}
