import Foundation

/// How a tvOS video card is presented. `feed` is Library / Search (existing chrome).
/// `recommended` is the YouTube TV home first row (~2.5 cards across).
/// `shelf` is the smaller rows beneath (~3.5 across).
enum TVOSVideoCardStyle: Equatable, Sendable {
    case feed
    case recommended
    case shelf

    var focusScale: CGFloat {
        switch self {
        case .feed: return 1.08
        case .recommended: return 1.05
        case .shelf: return 1.04
        }
    }

    var titleFontSize: CGFloat {
        switch self {
        case .feed: return 0
        case .recommended: return 28
        case .shelf: return 22
        }
    }

    var metaFontSize: CGFloat {
        switch self {
        case .feed: return 0
        case .recommended: return 20
        case .shelf: return 18
        }
    }

    var focusBorderWidth: CGFloat {
        switch self {
        case .feed: return 0
        case .recommended: return 4
        case .shelf: return 3
        }
    }
}

/// Card density for the tvOS home shelves, matching official YouTube on Apple TV:
/// Recommended shows ~2.5 landscape 16:9 cards; rows below show ~3.5.
/// Uses points (Apple TV 4K still layouts at 1920×1080 pt).
enum TVOSHomeShelfMetrics {
    static let recommendedVisibleCards: CGFloat = 2.5
    static let standardVisibleCards: CGFloat = 3.5
    static let cardSpacing: CGFloat = 24
    static let rowHorizontalPadding: CGFloat = 24
    static let recommendedRowVerticalPadding: CGFloat = 28
    static let standardRowVerticalPadding: CGFloat = 16
    static let rowHeaderFontSize: CGFloat = 28
    static let thumbnailCornerRadius: CGFloat = 8
    static let appleTV1080ContentWidth: CGFloat = 1848

    /// Width of one card so `visibleCards` fit in `containerWidth` with leading
    /// padding and gaps between the fully visible cards (the last is a peek).
    static func cardWidth(containerWidth: CGFloat, visibleCards: CGFloat) -> CGFloat {
        let gaps = visibleCards.rounded(.down)
        let available = containerWidth - rowHorizontalPadding - gaps * cardSpacing
        guard visibleCards > 0, available > 0 else { return 0 }
        return available / visibleCards
    }

    static var recommendedCardWidth1080: CGFloat {
        cardWidth(containerWidth: appleTV1080ContentWidth, visibleCards: recommendedVisibleCards)
    }

    static var standardCardWidth1080: CGFloat {
        cardWidth(containerWidth: appleTV1080ContentWidth, visibleCards: standardVisibleCards)
    }
}
