import Foundation

/// Focusable controls in the tvOS in-player bottom bar.
///
/// Transport left/right does **not** move this highlight — those D-pad events
/// seek (YouTube Apple TV). Up/down moves between the info, transport, and
/// action rows; left/right on the info and action rows steps between buttons.
enum TVOSPlayerControl: Equatable, Hashable {
    case channel, subscribe
    case playPause
    case prevVideo, nextVideo
    case like, dislike, comments, save, more
}

/// D-pad directions used by `TVOSPlayerControlPolicy`, independent of SwiftUI
/// so the layout can be unit-tested without importing `MoveCommandDirection`.
enum TVOSMoveDirection: Equatable {
    case left, right, up, down
}

/// Testable tvOS player-chrome navigation. Visual seek buttons stay in the
/// overlay for affordance; Siri Remote Left/Right on the transport row seek
/// instead of highlighting them.
enum TVOSPlayerControlPolicy {

    static func isTransport(_ control: TVOSPlayerControl) -> Bool {
        control == .playPause
    }

    /// Left/Right on the transport row seek rather than moving the highlight.
    static func seeksInsteadOfMovingHighlight(
        control: TVOSPlayerControl,
        direction: TVOSMoveDirection
    ) -> Bool {
        isTransport(control) && (direction == .left || direction == .right)
    }

    static func next(
        from current: TVOSPlayerControl,
        direction: TVOSMoveDirection
    ) -> TVOSPlayerControl {
        switch direction {
        case .left:
            switch current {
            case .subscribe: return .channel
            case .nextVideo: return .playPause
            case .playPause: return .prevVideo
            case .dislike: return .like
            case .comments: return .dislike
            case .save: return .comments
            case .more: return .save
            default: return current
            }
        case .right:
            switch current {
            case .channel: return .subscribe
            case .prevVideo: return .playPause
            case .playPause: return .nextVideo
            case .like: return .dislike
            case .dislike: return .comments
            case .comments: return .save
            case .save: return .more
            default: return current
            }
        case .up:
            switch current {
            case .like, .dislike, .comments, .save, .more:
                return .playPause
            case .playPause, .prevVideo, .nextVideo:
                return .subscribe
            default:
                return current
            }
        case .down:
            switch current {
            case .channel, .subscribe:
                return .playPause
            case .playPause, .prevVideo, .nextVideo:
                return .like
            default:
                return current
            }
        }
    }
}
