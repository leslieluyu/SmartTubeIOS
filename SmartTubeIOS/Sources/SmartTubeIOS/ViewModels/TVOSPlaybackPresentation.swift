import Foundation
import Observation

/// Tracks whether the tvOS player is covering browse chrome.
///
/// Home / Search / Library push `PlayerView` via `navigationDestination`, which
/// leaves `TVOSSidebarView` as a sibling in `MainTVTabView`'s `HStack`. The
/// player registers here on appear; the tab view collapses the rail to zero
/// width (kept in the stack so navigation identity is stable) until Back pops
/// the player.
@MainActor
@Observable
final class TVOSPlaybackPresentation {
    private(set) var isFullscreen = false

    func beginFullscreenSession() {
        isFullscreen = true
    }

    func endFullscreenSession() {
        isFullscreen = false
    }
}
