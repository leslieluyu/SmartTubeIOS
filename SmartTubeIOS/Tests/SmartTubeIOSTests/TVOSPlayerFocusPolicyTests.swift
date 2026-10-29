import Foundation
import Testing

@testable import SmartTubeIOS

@Suite("tvOS player focus restore policy")
struct TVOSPlayerFocusPolicyTests {

    @Test("restore delay is longer than the overlay focus-claim sleep")
    func restoreDelayOutlastsOverlayClaim() {
        #expect(TVOSPlayerFocusPolicy.restoreDelayNanoseconds > 50_000_000)
        #expect(TVOSPlayerFocusPolicy.restoreDelayNanoseconds <= 150_000_000)
    }

    @Test("lost player focus is restored while no overlay or skip toast is up")
    func restoresPlayerWhenIdleAndUnfocused() {
        #expect(
            TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
                playerFocused: false,
                overlayVisible: false,
                skipToastActive: false,
                isVisible: true,
                hasPushedDestination: false))
    }

    @Test("does not steal focus from an open options or quality overlay")
    func doesNotRestorePlayerWhileOverlayVisible() {
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
                playerFocused: false,
                overlayVisible: true,
                skipToastActive: false,
                isVisible: true,
                hasPushedDestination: false))
    }

    @Test("does not steal focus from the SponsorBlock skip toast")
    func doesNotRestorePlayerWhileSkipToastActive() {
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
                playerFocused: false,
                overlayVisible: false,
                skipToastActive: true,
                isVisible: true,
                hasPushedDestination: false))
    }

    @Test("already-focused player is left alone")
    func doesNotRestoreWhenAlreadyFocused() {
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
                playerFocused: true,
                overlayVisible: false,
                skipToastActive: false,
                isVisible: true,
                hasPushedDestination: false))
    }

    @Test("hidden or covered player does not reclaim the remote")
    func doesNotRestoreWhenNotVisibleOrPushedAway() {
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
                playerFocused: false,
                overlayVisible: false,
                skipToastActive: false,
                isVisible: false,
                hasPushedDestination: false))
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
                playerFocused: false,
                overlayVisible: false,
                skipToastActive: false,
                isVisible: true,
                hasPushedDestination: true))
        #expect(
            !TVOSPlayerFocusPolicy.shouldKeepPlayerSessionFocus(
                isVisible: true, hasPushedDestination: true))
    }

    @Test("more-menu row is restored after a format-list rebuild drops the binding")
    func restoresMoreMenuRowWhenDropped() {
        #expect(
            TVOSPlayerFocusPolicy.restoredMoreMenuRow(
                overlayVisible: true, moreMenuVisible: true, currentRowIsNil: true))
        #expect(
            !TVOSPlayerFocusPolicy.restoredMoreMenuRow(
                overlayVisible: true, moreMenuVisible: true, currentRowIsNil: false))
        #expect(
            !TVOSPlayerFocusPolicy.restoredMoreMenuRow(
                overlayVisible: false, moreMenuVisible: true, currentRowIsNil: true))
    }

    @Test("quality picker focus is restored when the overlay list rebuilds")
    func restoresQualityPickerFocusWhenDropped() {
        #expect(
            TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true, pickerVisible: true, pickerFocused: false))
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true, pickerVisible: true, pickerFocused: true))
        #expect(
            !TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true, pickerVisible: false, pickerFocused: false))
    }
}
