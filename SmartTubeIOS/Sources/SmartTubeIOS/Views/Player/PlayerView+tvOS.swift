import SmartTubeIOSCore
import SwiftUI

// MARK: - PlayerView tvOS extensions
//
// All tvOS-specific logic for PlayerView: the control navigation model,
// the Siri Remote key handlers (tvNextControl / tvActivateControl),
// and the custom tvOS progress bar layout.
// Body modifiers (.focusable, .onMoveCommand, etc.) and stored properties
// (@FocusState, @State highlightedControl) remain in PlayerView.swift because
// Swift does not allow stored properties in extensions.

#if os(tvOS)

extension TVOSMoveDirection {
    init?(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: self = .left
        case .right: self = .right
        case .up: self = .up
        case .down: self = .down
        @unknown default: return nil
        }
    }
}

// MARK: - ConditionalMoveCommand

/// Conditionally applies `.onMoveCommand`. When `enabled = false` the modifier is
/// completely absent from the view tree (not just a no-op closure), which allows
/// D-pad events to fall through to SwiftUI's native focus engine so it can move
/// focus between buttons inside an overlay's VStack.
///
/// `.onMoveCommand(perform: nil)` is NOT equivalent — it still registers a
/// modifier node in the responder chain and can prevent the focus engine from
/// receiving the event.
struct ConditionalMoveCommand: ViewModifier {
    let enabled: Bool
    let action: (MoveCommandDirection) -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.onMoveCommand(perform: action)
        } else {
            content  // modifier completely absent — D-pad reaches native focus engine
        }
    }
}

extension PlayerView {

    // MARK: - MoreMenuRow

    /// Identifies each focusable row in the more menu overlay.
    /// Navigation is native SwiftUI focus via the `.focused($moreMenuFocusedRow, equals:)`
    /// binding on each row; initial focus is set to `.speed` when the menu opens
    /// (PlayerView+Lifecycle). The case value drives the row's focus highlight.
    enum MoreMenuRow: Hashable {
        case speed, quality, like, dislike, sleepTimer, audioOnly, queueShuffle, captions,
            audioTrack, description, comments, statsForNerds, cancel
    }

    /// Software-highlight target in the YouTube-style bottom bar.
    /// Alias of `TVOSPlayerControl` so existing `PlayerView.TVPlayerControl`
    /// call sites (overlay, UI tests' identifiers) keep compiling.
    typealias TVPlayerControl = TVOSPlayerControl

    // MARK: - Overlay state

    /// True when any picker or menu overlay is open.
    /// When true, the player yields focus to the overlay so its buttons
    /// are reachable by the Siri Remote.
    var isAnyOverlayVisible: Bool {
        showMoreMenu || showQualityPicker || showSpeedPicker || showSleepTimerPicker || showCaptionPicker
            || showAudioTrackPicker
            || showDescriptionSheet || showCommentsSheet
    }

    /// True while a SponsorBlock skip toast is visible.
    /// Kept separate from `isAnyOverlayVisible` so the `onChange(of: isAnyOverlayVisible)`
    /// handler's `vm.cancelControlsHide()` call is not triggered by the transient toast.
    var isSkipToastActive: Bool {
        vm.currentToastSegment != nil
    }

    // MARK: - Controls navigation

    /// Returns the next control to highlight when the user presses a d-pad direction.
    func tvNextControl(from current: TVPlayerControl, direction: MoveCommandDirection) -> TVPlayerControl {
        guard let move = TVOSMoveDirection(direction) else { return current }
        if TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(control: current, direction: move) {
            return current
        }
        return TVOSPlayerControlPolicy.next(from: current, direction: move)
    }

    // MARK: - Focus restore

    /// Re-assert player or overlay focus after a late `@Observable` update (4K
    /// overlay merge, composition item swap) can drop `@FocusState`. Delayed so
    /// an opening menu can claim the remote first.
    func scheduleTVOSFocusReconcile() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: TVOSPlayerFocusPolicy.restoreDelayNanoseconds)
            reconcileTVOSFocus()
        }
    }

    func reconcileTVOSFocus() {
        let playerLog = CrashlyticsLogger(category: "Player")
        guard
            TVOSPlayerFocusPolicy.shouldKeepPlayerSessionFocus(
                isVisible: isVisible,
                hasPushedDestination: channelDestination != nil)
        else { return }

        if isAnyOverlayVisible {
            if TVOSPlayerFocusPolicy.restoredMoreMenuRow(
                overlayVisible: true,
                moreMenuVisible: showMoreMenu,
                currentRowIsNil: moreMenuFocusedRow == nil)
            {
                moreMenuFocusedRow = .speed
                playerLog.notice("[tv] restored moreMenuFocusedRow → .speed")
            }
            if TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true,
                pickerVisible: showQualityPicker,
                pickerFocused: qualityPickerFocused)
            {
                qualityPickerFocused = true
                playerLog.notice("[tv] restored qualityPickerFocused")
            }
            if TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true,
                pickerVisible: showSpeedPicker,
                pickerFocused: speedPickerFocused)
            {
                speedPickerFocused = true
            }
            if TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true,
                pickerVisible: showSleepTimerPicker,
                pickerFocused: sleepTimerPickerFocused)
            {
                sleepTimerPickerFocused = true
            }
            if TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true,
                pickerVisible: showCaptionPicker,
                pickerFocused: captionPickerFocused)
            {
                captionPickerFocused = true
            }
            if TVOSPlayerFocusPolicy.shouldRestorePickerFocus(
                overlayVisible: true,
                pickerVisible: showAudioTrackPicker,
                pickerFocused: audioTrackPickerFocused)
            {
                audioTrackPickerFocused = true
            }
            return
        }

        if isSkipToastActive {
            if !skipToastButtonFocused {
                skipToastButtonFocused = true
            }
            return
        }

        if TVOSPlayerFocusPolicy.shouldRestorePlayerFocus(
            playerFocused: playerFocused,
            overlayVisible: false,
            skipToastActive: false,
            isVisible: isVisible,
            hasPushedDestination: channelDestination != nil)
        {
            playerLog.notice("[tv] restoring playerFocused after unexpected loss")
            playerFocused = true
        }
    }

    /// Executes the action for the currently highlighted control.
    func tvActivateControl(_ control: TVPlayerControl) {
        let playerLog = CrashlyticsLogger(category: "Player")
        playerLog.notice("[tv] tvActivateControl(\(String(describing: control)))")
        let currentVideo = vm.playerInfo?.video ?? video
        switch control {
        case .channel:
            let channelId = currentVideo.channelId ?? video.channelId
            if let cid = channelId, !cid.isEmpty { channelDestination = ChannelDestination(channelId: cid) }
        case .subscribe:
            toggleChannelFollow()
        case .more:
            playerLog.notice("[tv] .more activated — setting showMoreMenu=true")
            showMoreMenu = true
            highlightedControl = nil
        case .playPause: vm.togglePlayPause()
        case .like: vm.like()
        case .dislike: vm.dislike()
        case .comments:
            showCommentsSheet = true
            highlightedControl = nil
            loadComments()
        case .save:
            toggleWatchLater()
        case .prevVideo: if vm.hasPrevious { vm.playPrevious() }
        case .nextVideo: if vm.hasNext { vm.playNext() }
        }
    }

    func toggleChannelFollow() {
        let currentVideo = vm.playerInfo?.video ?? video
        guard let channelId = currentVideo.channelId, !channelId.isEmpty else { return }
        let followed = isChannelFollowed
        Task { @MainActor in
            if followed {
                await LocalSubscriptionStore.shared.unfollow(channelId: channelId)
                isChannelFollowed = false
            } else {
                await LocalSubscriptionStore.shared.follow(
                    LocalChannel(
                        id: channelId,
                        title: currentVideo.channelTitle,
                        thumbnailURL: currentVideo.thumbnailURL
                    )
                )
                isChannelFollowed = true
            }
        }
    }

    func toggleWatchLater() {
        guard authService.isSignedIn else { return }
        let currentVideo = vm.playerInfo?.video ?? video
        let saved = isSavedToWatchLater
        Task { @MainActor in
            do {
                if saved {
                    if let token = WatchLaterMembershipStore.shared.setVideoId(for: currentVideo.id) {
                        try await innerTubeAPI.removeFromWatchLater(setVideoId: token)
                    }
                    WatchLaterMembershipStore.shared.markRemoved(currentVideo.id)
                    isSavedToWatchLater = false
                } else {
                    let token = try await innerTubeAPI.addToWatchLater(videoId: currentVideo.id)
                    WatchLaterMembershipStore.shared.markSaved(currentVideo, setVideoId: token)
                    isSavedToWatchLater = true
                }
            } catch {
                vm.toastMessage = error.localizedDescription
            }
        }
    }

}

extension PlayerControlsOverlay {

    // MARK: - YouTube-style bottom chrome

    /// Bottom-aligned player bar: description, subscribe, transport, and
    /// like / dislike / comments / save / options. Software highlight only —
    /// native focus stays on the player body (4K overlay Select fix).
    var tvosBottomChrome: some View {
        let currentVideo = vm.playerInfo?.video ?? video
        let channelId = currentVideo.channelId ?? video.channelId
        let description = currentVideo.description ?? video.description ?? ""
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 14) {
                Text(currentVideo.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .accessibilityIdentifier("player.chromeTitle")

                if !description.isEmpty {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                        .accessibilityIdentifier("player.descriptionLabel")
                }

                HStack(spacing: 20) {
                    tvOverlayControl(
                        highlighted: highlightedControl == .channel,
                        scale: 1.12,
                        shadowRadius: 10,
                        identifier: "player.channelName",
                        enabled: channelId?.isEmpty == false
                    ) {
                        Text(currentVideo.channelTitle)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    tvOverlayControl(
                        highlighted: highlightedControl == .subscribe,
                        scale: 1.1,
                        shadowRadius: 10,
                        identifier: "player.subscribeButton",
                        enabled: channelId?.isEmpty == false
                    ) {
                        Text(isChannelFollowed ? "Subscribed" : "Subscribe")
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(
                                isChannelFollowed ? Color.white.opacity(0.22) : Color.red,
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                }

                if let chapter = vm.currentChapter {
                    Text(chapter.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }

                progressBar
                    .accessibilityIdentifier("player.progressBar")

                HStack(spacing: 20) {
                    HStack(spacing: 36) {
                        tvOverlayControl(
                            highlighted: highlightedControl == .prevVideo,
                            scale: 1.2,
                            shadowRadius: 10,
                            identifier: "player.prevBtn",
                            enabled: vm.hasPrevious && !vm.isLoading,
                            width: 56,
                            height: 56
                        ) {
                            Image(systemName: AppSymbol.previousTrack)
                                .font(.title2)
                                .foregroundStyle(vm.hasPrevious && !vm.isLoading ? .white : .white.opacity(0.3))
                        }
                        seekButton(
                            symbol: "gobackward.\(store.settings.seekBackSeconds)",
                            seconds: -Double(store.settings.seekBackSeconds),
                            tvHighlighted: false)
                        playPauseButton
                        seekButton(
                            symbol: "goforward.\(store.settings.seekForwardSeconds)",
                            seconds: Double(store.settings.seekForwardSeconds),
                            tvHighlighted: false)
                        tvOverlayControl(
                            highlighted: highlightedControl == .nextVideo,
                            scale: 1.2,
                            shadowRadius: 10,
                            identifier: "player.nextBtn",
                            enabled: vm.hasNext,
                            width: 56,
                            height: 56
                        ) {
                            Image(systemName: AppSymbol.nextTrack)
                                .font(.title2)
                                .foregroundStyle(vm.hasNext ? .white : .white.opacity(0.3))
                        }
                    }
                    Spacer(minLength: 16)
                    HStack(spacing: 14) {
                        tvActionGlyph(
                            control: .like,
                            identifier: "player.likeButton",
                            systemName: vm.likeStatus == .like
                                ? "\(AppSymbol.thumbsUp).fill" : AppSymbol.thumbsUp,
                            accented: vm.likeStatus == .like
                        )
                        tvActionGlyph(
                            control: .dislike,
                            identifier: "player.dislikeButton",
                            systemName: vm.likeStatus == .dislike
                                ? "\(AppSymbol.thumbsDown).fill" : AppSymbol.thumbsDown,
                            accented: vm.likeStatus == .dislike
                        )
                        tvActionGlyph(
                            control: .comments,
                            identifier: "player.commentsButton",
                            systemName: "bubble.left.and.bubble.right"
                        )
                        tvActionGlyph(
                            control: .save,
                            identifier: "player.saveButton",
                            systemName: isSavedToWatchLater
                                ? "\(AppSymbol.watchLater).fill" : AppSymbol.watchLater,
                            accented: isSavedToWatchLater
                        )
                        tvActionGlyph(
                            control: .more,
                            identifier: "player.moreButton",
                            systemName: "ellipsis"
                        )
                    }
                }
                .disabled(vm.isLoading)
                .opacity(vm.isLoading ? 0.35 : 1)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 36)
            .padding(.top, 20)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55), .black.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                .focusable(false)
            )
        }
        .allowsHitTesting(false)
        .focusable(false)
    }

    func tvActionGlyph(
        control: PlayerView.TVPlayerControl,
        identifier: String,
        systemName: String,
        accented: Bool = false
    ) -> some View {
        tvOverlayControl(
            highlighted: highlightedControl == control,
            scale: 1.28,
            shadowRadius: 10,
            identifier: identifier,
            width: 64,
            height: 64
        ) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(accented ? Color.accentColor : .white)
        }
    }

    // MARK: - tvOS progress bar

    /// Custom progress bar for tvOS: larger thumb, wider padding, bigger time labels.
    /// The iOS variant (`iosProgressBar`) lives in PlayerView+ControlElements.swift.
    var tvProgressBar: some View {
        VStack(spacing: 6) {
            // Scrub time tooltip
            GeometryReader { geo in
                if vm.isScrubbing && vm.duration > 0 {
                    let hPad: CGFloat = 40
                    let trackW = geo.size.width - hPad * 2
                    let fraction = CGFloat(vm.scrubTime / vm.duration)
                    let thumbX = hPad + trackW * fraction
                    let chapterAtScrub = vm.chapters.last(where: { $0.startTime <= vm.scrubTime })
                    let labelW: CGFloat = chapterAtScrub != nil ? min(geo.size.width * 0.45, 220) : 90
                    let clampedX = min(max(thumbX, hPad + labelW / 2), geo.size.width - hPad - labelW / 2)

                    VStack(spacing: 2) {
                        if let chapter = chapterAtScrub {
                            Text(chapter.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        Text(formatDuration(vm.scrubTime))
                            .font(.body.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                    .frame(width: labelW)
                    .position(x: clampedX, y: geo.size.height / 2)
                }
            }
            .frame(height: 36)

            // Track row
            GeometryReader { geo in
                let hPad: CGFloat = 40
                let trackW = geo.size.width - hPad * 2
                let time = vm.isScrubbing ? vm.scrubTime : vm.currentTime
                let progress = vm.duration > 0 ? CGFloat(time / vm.duration) : 0
                let thumbX = hPad + trackW * progress

                ZStack {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 6)
                        .padding(.horizontal, hPad)

                    // Progress fill
                    HStack(spacing: 0) {
                        Capsule()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: max(thumbX - hPad, 0), height: 6)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, hPad)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                        .position(x: thumbX, y: geo.size.height / 2)
                }
                .overlay(sponsorBlockMarkers)
                .overlay(chapterMarkers)
            }
            .frame(height: 36)

            // Time labels
            HStack {
                Text(formatDuration(vm.currentTime))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.leading, 40)
                Spacer()
                Text(formatDuration(vm.duration))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.trailing, 40)
            }
        }
    }
}
#endif
