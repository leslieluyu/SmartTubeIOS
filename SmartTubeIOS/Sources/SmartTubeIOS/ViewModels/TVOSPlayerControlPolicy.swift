import Foundation

/// Focusable controls in the tvOS in-player bottom bar.
///
/// While chrome is hidden, Left/Right seek. While chrome is visible, Left/Right
/// move this highlight among the bottom icons — they do **not** seek, except
/// when the scrubber itself is highlighted (timeline nudge).
enum TVOSPlayerControl: Equatable, Hashable {
    case channel, subscribe
    case scrubber
    case playPause
    case prevVideo, nextVideo
    case like, dislike, comments, save, more
}

/// D-pad directions used by `TVOSPlayerControlPolicy`, independent of SwiftUI
/// so the layout can be unit-tested without importing `MoveCommandDirection`.
enum TVOSMoveDirection: Equatable {
    case left, right, up, down
}

/// Result of a Siri Remote D-pad event against the in-player chrome.
enum TVOSPlayerMoveOutcome: Equatable {
    /// Perform a relative seek. Chrome stays hidden if it was hidden.
    case seek
    /// Show chrome if needed and move the software highlight.
    case highlight(TVOSPlayerControl)
}

/// Testable tvOS player-chrome navigation.
///
/// Mode A (chrome hidden): Left/Right seek; Select or Down reveals the bar on
/// Play/Pause; Up reveals the bar on the scrubber.
/// Mode B (chrome visible): Left/Right walk bottom icons; Up highlights the
/// scrubber. Native focus stays on the player body so 4K Select restore
/// (`TVOSPlayerFocusPolicy`) is unchanged.
enum TVOSPlayerControlPolicy {

    /// Bottom-row icons walked by Left/Right while chrome is visible.
    /// Seek-back/forward glyphs stay visual affordances only.
    static let bottomIcons: [TVOSPlayerControl] = [
        .prevVideo, .playPause, .nextVideo, .like, .dislike, .comments, .save, .more,
    ]

    /// Software focus when Select or Down reveals the bar.
    static let defaultChromeFocus: TVOSPlayerControl = .playPause

    static func isTransport(_ control: TVOSPlayerControl) -> Bool {
        control == .playPause
    }

    static func isBottomIcon(_ control: TVOSPlayerControl) -> Bool {
        bottomIcons.contains(control)
    }

    /// Left/Right seek only while chrome is hidden, or while the scrubber is
    /// the highlighted control (timeline nudge). Play/Pause never seeks when
    /// the bar is up.
    static func seeksInsteadOfMovingHighlight(
        chromeVisible: Bool,
        control: TVOSPlayerControl?,
        direction: TVOSMoveDirection
    ) -> Bool {
        guard direction == .left || direction == .right else { return false }
        if !chromeVisible { return true }
        return control == .scrubber
    }

    /// Focus after revealing chrome with a D-pad direction (Select uses
    /// `defaultChromeFocus` instead).
    static func initialFocus(revealingWith direction: TVOSMoveDirection) -> TVOSPlayerControl {
        direction == .up ? .scrubber : .playPause
    }

    static func next(
        from current: TVOSPlayerControl,
        direction: TVOSMoveDirection
    ) -> TVOSPlayerControl {
        switch direction {
        case .left:
            switch current {
            case .subscribe: return .channel
            case .channel, .scrubber: return current
            default: return neighbor(in: bottomIcons, of: current, step: -1)
            }
        case .right:
            switch current {
            case .channel: return .subscribe
            case .subscribe, .scrubber: return current
            default: return neighbor(in: bottomIcons, of: current, step: 1)
            }
        case .up:
            switch current {
            case .channel, .subscribe:
                return current
            case .scrubber:
                return .subscribe
            default:
                return .scrubber
            }
        case .down:
            switch current {
            case .channel, .subscribe:
                return .scrubber
            case .scrubber:
                return .playPause
            default:
                return current
            }
        }
    }

    /// Single entry used by the player D-pad handler and unit tests.
    static func outcome(
        chromeVisible: Bool,
        highlighted: TVOSPlayerControl?,
        direction: TVOSMoveDirection
    ) -> TVOSPlayerMoveOutcome {
        if seeksInsteadOfMovingHighlight(
            chromeVisible: chromeVisible, control: highlighted, direction: direction)
        {
            return .seek
        }
        if !chromeVisible {
            return .highlight(initialFocus(revealingWith: direction))
        }
        guard let highlighted else {
            switch direction {
            case .up:
                return .highlight(.scrubber)
            case .down:
                return .highlight(.playPause)
            case .left, .right:
                return .highlight(next(from: .playPause, direction: direction))
            }
        }
        return .highlight(next(from: highlighted, direction: direction))
    }

    private static func neighbor(
        in items: [TVOSPlayerControl],
        of current: TVOSPlayerControl,
        step: Int
    ) -> TVOSPlayerControl {
        guard let index = items.firstIndex(of: current) else { return current }
        let nextIndex = index + step
        guard items.indices.contains(nextIndex) else { return current }
        return items[nextIndex]
    }
}
