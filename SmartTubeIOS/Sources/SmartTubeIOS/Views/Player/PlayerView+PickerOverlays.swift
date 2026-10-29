import AVKit
import SmartTubeIOSCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

private let pickerLog = CrashlyticsLogger(category: "PlayerMenu")

// MARK: - PlayerView picker overlays + share sheet
//
// Pure-SwiftUI overlays for all media settings pickers.
// tvOS: dense right-side drawer over fullscreen dimmed video.
// iOS: bottom sheet. Rendered inside the player's ZStack so no UIKit
// sheet presentation fires onDisappear and tears down playback.
//
// Includes:
//   • qualityPickerOverlay       — video quality selection
//   • speedPickerOverlay         — playback speed selection
//   • sleepTimerPickerOverlay    — sleep timer duration
//   • captionPickerOverlay       — subtitle/caption track selection
//   • audioTrackPickerOverlay    — audio track selection
//   • presentShareSheet(url:)    — UIActivityViewController (iOS only)

extension PlayerView {

    @ViewBuilder
    func playerPickerHeader(title: String, dismiss: @escaping () -> Void) -> some View {
        #if os(tvOS)
        TVOSSettingsPanelHeader(title: title)
            .onExitCommand(perform: dismiss)
        Divider().opacity(0.35)
        #else
        HStack {
            Button("Cancel") { dismiss() }
                .padding()
            Spacer()
            Text(title)
                .fontWeight(.semibold)
            Spacer()
            Color.clear.frame(width: 70, height: 44)
        }
        Divider()
        #endif
    }

    func pickerListMaxHeight(_ iOSMax: CGFloat = 320) -> CGFloat {
        #if os(tvOS)
        .infinity
        #else
        iOSMax
        #endif
    }

    // MARK: - Quality picker overlay

    var qualityPickerOverlay: some View {
        ZStack(alignment: overlayPanelAlignment) {
            Color.black.opacity(settingsOverlayScrimOpacity)
                .ignoresSafeArea()
                .playerOverlayScrimDismiss { showQualityPicker = false }
            VStack(spacing: 0) {
                playerPickerHeader(title: "Quality", dismiss: { showQualityPicker = false })
                ScrollView {
                    VStack(spacing: 0) {
                        Button {
                            pickerLog.notice(
                                "[qualityPicker] selected Auto (was: \(vm.selectedFormat?.qualityLabel ?? "Auto"))")
                            vm.selectFormat(nil)
                            showQualityPicker = false
                            qualityToastMessage = "Auto quality"
                        } label: {
                            HStack {
                                Text("Auto")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if vm.selectedFormat == nil {
                                    Image(systemName: AppSymbol.checkmark)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .playerSettingsRowLabelInsets()
                        }
                        .playerSettingsRowButtonStyle()
                        #if os(tvOS)
                        .prefersDefaultFocus(in: qualityPickerNamespace)
                        #endif
                        Divider()
                        ForEach(vm.availableFormats) { fmt in
                            Button {
                                pickerLog.notice(
                                    "[qualityPicker] selected \(fmt.qualityLabel) (was: \(vm.selectedFormat?.qualityLabel ?? "Auto"))"
                                )
                                vm.selectFormat(fmt)
                                showQualityPicker = false
                                qualityToastMessage = "\(fmt.qualityLabel) · may take up to 30s"
                            } label: {
                                HStack {
                                    Text(fmt.qualityLabel)
                                        .foregroundStyle(.primary)
                                    if !fmt.codecShortLabel.isEmpty {
                                        Text(fmt.codecShortLabel)
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    if vm.selectedFormat?.id == fmt.id {
                                        Image(systemName: AppSymbol.checkmark)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .playerSettingsRowLabelInsets()
                            }
                            .playerSettingsRowButtonStyle()
                            // Explicit accessibility label keeps XCTest queries like
                            // `label BEGINSWITH "720p"` working even when the button HStack
                            // contains multiple Text views (e.g. the codec short label).
                            .accessibilityLabel(fmt.qualityLabel)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: pickerListMaxHeight())
                #if os(tvOS)
                .prefersDefaultFocus(in: qualityPickerNamespace)
                .focused($qualityPickerFocused)
                #endif
            }
            .modifier(PlayerOverlayPanelModifier(iOSMaxWidth: moreMenuPortraitWidth))
            .accessibilityIdentifier("player.qualityPicker")
            .task {
                // Fix 2A: pre-warm all quality tiers the moment the picker opens so that
                // by the time the user taps a resolution, tracks are cached (< 100ms switch).
                await vm.prefetchAllQualityTracks()
            }
            #if os(tvOS)
            .focusScope(qualityPickerNamespace)
            .onExitCommand {
                pickerLog.notice("[qualityPicker] onExitCommand fired — dismissing")
                showQualityPicker = false
            }
            #endif
        }
        .ignoresSafeArea()
    }

    // MARK: - Speed picker overlay

    var speedPickerOverlay: some View {
        ZStack(alignment: overlayPanelAlignment) {
            Color.black.opacity(settingsOverlayScrimOpacity)
                .ignoresSafeArea()
                .playerOverlayScrimDismiss { showSpeedPicker = false }
            VStack(spacing: 0) {
                playerPickerHeader(title: "Playback Speed", dismiss: { showSpeedPicker = false })
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(AppSettings.availableSpeeds, id: \.self) { (speed: Double) in
                            Button {
                                store.settings.playbackSpeed = speed
                                vm.setPlaybackSpeed(speed)
                                showSpeedPicker = false
                            } label: {
                                HStack {
                                    Text(speed == 1.0 ? "Normal (1\u{d7})" : "\(speed, specifier: "%.2g")\u{d7}")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if abs(store.settings.playbackSpeed - speed) < 0.01 {
                                        Image(systemName: AppSymbol.checkmark)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .playerSettingsRowLabelInsets()
                            }
                            .playerSettingsRowButtonStyle()
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: pickerListMaxHeight())
                #if os(tvOS)
                .prefersDefaultFocus(in: speedPickerNamespace)
                .focused($speedPickerFocused)
                #endif
            }
            .modifier(PlayerOverlayPanelModifier(iOSMaxWidth: moreMenuPortraitWidth))
            .accessibilityIdentifier("player.speedPicker")
            #if os(tvOS)
            .focusScope(speedPickerNamespace)
            .onExitCommand {
                pickerLog.notice("[speedPicker] onExitCommand fired — dismissing")
                showSpeedPicker = false
            }
            #endif
        }
        .ignoresSafeArea()
    }

    // MARK: - Sleep timer picker overlay

    var sleepTimerPickerOverlay: some View {
        ZStack(alignment: overlayPanelAlignment) {
            Color.black.opacity(settingsOverlayScrimOpacity)
                .ignoresSafeArea()
                .playerOverlayScrimDismiss { showSleepTimerPicker = false }
            VStack(spacing: 0) {
                playerPickerHeader(title: "Sleep Timer", dismiss: { showSleepTimerPicker = false })
                VStack(spacing: 0) {
                    Button {
                        vm.setSleepTimer(minutes: nil)
                        showSleepTimerPicker = false
                    } label: {
                        HStack {
                            Text("Off")
                                .foregroundStyle(.primary)
                            Spacer()
                            if vm.sleepTimerMinutes == nil {
                                Image(systemName: AppSymbol.checkmark)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .playerSettingsRowLabelInsets()
                    }
                    .playerSettingsRowButtonStyle()
                    #if os(tvOS)
                    .prefersDefaultFocus(in: sleepTimerNamespace)
                    .focused($sleepTimerPickerFocused)
                    #endif
                    Divider()
                    ForEach(PlaybackViewModel.sleepTimerOptions, id: \.self) { mins in
                        Button {
                            vm.setSleepTimer(minutes: mins)
                            showSleepTimerPicker = false
                        } label: {
                            HStack {
                                Text("\(mins) min")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if vm.sleepTimerMinutes == mins {
                                    Image(systemName: AppSymbol.checkmark)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .playerSettingsRowLabelInsets()
                        }
                        .playerSettingsRowButtonStyle()
                        Divider()
                    }
                }
                .frame(maxHeight: pickerListMaxHeight())
            }
            .modifier(PlayerOverlayPanelModifier(iOSMaxWidth: moreMenuPortraitWidth))
            .accessibilityIdentifier("player.sleepTimerPicker")
            #if os(tvOS)
            .focusScope(sleepTimerNamespace)
            .onExitCommand {
                pickerLog.notice("[sleepTimerPicker] onExitCommand fired — dismissing")
                showSleepTimerPicker = false
            }
            #endif
        }
        .ignoresSafeArea()
    }

    // MARK: - Caption picker overlay

    var captionPickerOverlay: some View {
        ZStack(alignment: overlayPanelAlignment) {
            Color.black.opacity(settingsOverlayScrimOpacity)
                .ignoresSafeArea()
                .playerOverlayScrimDismiss { showCaptionPicker = false }
            VStack(spacing: 0) {
                playerPickerHeader(title: "Captions", dismiss: { showCaptionPicker = false })
                ScrollView {
                    VStack(spacing: 0) {
                        // Off row
                        Button {
                            vm.selectCaption(nil)
                            showCaptionPicker = false
                        } label: {
                            HStack {
                                Text("Off")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if vm.selectedCaption == nil {
                                    Image(systemName: AppSymbol.checkmark)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .playerSettingsRowLabelInsets()
                        }
                        .playerSettingsRowButtonStyle()
                        .accessibilityIdentifier("player.captionPicker.off")
                        #if os(tvOS)
                        .prefersDefaultFocus(in: captionPickerNamespace)
                        #endif
                        Divider()
                        ForEach(vm.availableCaptions) { track in
                            Button {
                                vm.selectCaption(track)
                                showCaptionPicker = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .foregroundStyle(.primary)
                                        if track.isAutoGenerated {
                                            Text("Auto-generated")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if vm.selectedCaption?.id == track.id {
                                        Image(systemName: AppSymbol.checkmark)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .playerSettingsRowLabelInsets()
                            }
                            .playerSettingsRowButtonStyle()
                            .accessibilityIdentifier("player.captionPicker.track.\(track.id)")
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: pickerListMaxHeight(360))
                #if os(tvOS)
                .focused($captionPickerFocused)
                #endif
            }
            .modifier(PlayerOverlayPanelModifier(iOSMaxWidth: moreMenuPortraitWidth))
            .accessibilityIdentifier("player.captionPicker")
            #if os(tvOS)
            .focusScope(captionPickerNamespace)
            .onExitCommand { showCaptionPicker = false }
            #endif
        }
        .ignoresSafeArea()
    }

    // MARK: - Audio track picker overlay

    var audioTrackPickerOverlay: some View {
        ZStack(alignment: overlayPanelAlignment) {
            Color.black.opacity(settingsOverlayScrimOpacity)
                .ignoresSafeArea()
                .playerOverlayScrimDismiss { showAudioTrackPicker = false }
            VStack(spacing: 0) {
                playerPickerHeader(title: "Audio Track", dismiss: { showAudioTrackPicker = false })
                ScrollView {
                    VStack(spacing: 0) {
                        // "Auto" row — resets to HLS default and clears the saved preference
                        Button {
                            vm.selectAudioTrack(nil)
                            showAudioTrackPicker = false
                        } label: {
                            HStack {
                                Text("Auto")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if vm.selectedAudioTrack == nil {
                                    Image(systemName: AppSymbol.checkmark)
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .playerSettingsRowLabelInsets()
                        }
                        .playerSettingsRowButtonStyle()
                        .accessibilityIdentifier("player.audioTrackPicker.auto")
                        #if os(tvOS)
                        .prefersDefaultFocus(in: audioTrackPickerNamespace)
                        #endif
                        Divider()
                        ForEach(vm.availableAudioTracks) { track in
                            Button {
                                vm.selectAudioTrack(track)
                                showAudioTrackPicker = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .foregroundStyle(.primary)
                                        if track.isOriginal {
                                            Text("Original")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if vm.selectedAudioTrack?.id == track.id {
                                        Image(systemName: AppSymbol.checkmark)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                                .playerSettingsRowLabelInsets()
                            }
                            .playerSettingsRowButtonStyle()
                            .accessibilityIdentifier("player.audioTrackPicker.track.\(track.id)")
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: pickerListMaxHeight(360))
                #if os(tvOS)
                .focused($audioTrackPickerFocused)
                #endif
            }
            .modifier(PlayerOverlayPanelModifier(iOSMaxWidth: moreMenuPortraitWidth))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("player.audioTrackPicker")
            #if os(tvOS)
            .focusScope(audioTrackPickerNamespace)
            .onExitCommand { showAudioTrackPicker = false }
            #endif
        }
        .ignoresSafeArea()
    }

    // MARK: - Share sheet

    #if os(iOS)
    func presentShareSheet(url: URL) {
        let wasPlaying = vm.isPlaying
        vm.suspend()
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            if wasPlaying { vm.resume() }
        }
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        // On iPad, UIActivityViewController must have a popover source or UIKit crashes.
        if let popover = vc.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(
                x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }
        top.present(vc, animated: true)
    }
    #endif
}
