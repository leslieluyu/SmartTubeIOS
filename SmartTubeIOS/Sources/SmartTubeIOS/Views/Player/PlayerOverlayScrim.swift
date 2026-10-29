import SwiftUI

extension View {
    /// Dimmer dismiss on iOS/macOS. On tvOS, `.onTapGesture` would register the
    /// full-screen Color as a focusable item and steal Siri Remote Select from
    /// menu / picker rows after a composition item swap.
    #if os(tvOS)
    func playerOverlayScrimDismiss(_: @escaping () -> Void) -> some View {
        self.allowsHitTesting(false).focusable(false)
    }
    #else
    func playerOverlayScrimDismiss(_ dismiss: @escaping () -> Void) -> some View {
        self.onTapGesture(perform: dismiss)
    }
    #endif
}
