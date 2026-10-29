import Foundation

/// Testable tvOS player-focus decisions so Siri Remote Select keeps working when
/// the 1440p/2160p composition overlay rebuilds the `AVPlayerItem`.
///
/// Late `@Observable` updates (overlay merge, quality switch, `isLoading` /
/// `isPlaying` flips) can reset `@FocusState playerFocused`. Overlay dimmers that
/// use `.onTapGesture` also become focusable on tvOS and can steal Select from
/// menu rows. This policy says when the player body may reclaim focus versus
/// when an open overlay / skip toast / pushed destination must keep it.
enum TVOSPlayerFocusPolicy {

    /// Wait one overlay-claim cycle (~50 ms) plus a short buffer so opening the
    /// more menu / quality picker can take focus before the player re-asserts.
    static let restoreDelayNanoseconds: UInt64 = 80_000_000

    /// True when this PlayerView is still the top-most visible session and may
    /// own the Siri Remote. Channel pushes leave the player in the stack.
    static func shouldKeepPlayerSessionFocus(
        isVisible: Bool,
        hasPushedDestination: Bool
    ) -> Bool {
        isVisible && !hasPushedDestination
    }

    /// Re-assert `playerFocused` only when nothing else should own the remote.
    static func shouldRestorePlayerFocus(
        playerFocused: Bool,
        overlayVisible: Bool,
        skipToastActive: Bool,
        isVisible: Bool,
        hasPushedDestination: Bool
    ) -> Bool {
        shouldKeepPlayerSessionFocus(
            isVisible: isVisible, hasPushedDestination: hasPushedDestination)
            && !playerFocused
            && !overlayVisible
            && !skipToastActive
    }

    /// After a format-list rebuild, restore the more-menu row if the menu is
    /// open and SwiftUI dropped the row binding.
    static func restoredMoreMenuRow(
        overlayVisible: Bool,
        moreMenuVisible: Bool,
        currentRowIsNil: Bool
    ) -> Bool {
        overlayVisible && moreMenuVisible && currentRowIsNil
    }

    /// After a format-list rebuild, restore picker focus if that picker is open
    /// and its `FocusState` dropped to false.
    static func shouldRestorePickerFocus(
        overlayVisible: Bool,
        pickerVisible: Bool,
        pickerFocused: Bool
    ) -> Bool {
        overlayVisible && pickerVisible && !pickerFocused
    }
}
