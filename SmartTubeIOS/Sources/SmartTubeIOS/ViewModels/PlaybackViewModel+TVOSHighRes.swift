import Foundation
import SmartTubeIOSCore

private let playerLog = CrashlyticsLogger(category: "Player")

// MARK: - tvOS 1440p / 2160p overlay
//
// Signed-in Apple TV cold-start stays on authenticated TVHTML5 HLS (typically 1080p).
// After that ladder is playing, a background fetch asks Android then WebCreator for
// progressive video/mp4 URLs at 1440p+ that AVPlayer can decode (H.264 / HEVC / AV1).
// Those rows are merged into the quality picker; selecting one plays via
// AVMutableComposition. Failure reloads the original HLS item.

extension PlaybackViewModel {

    /// Starts a single overlay fetch per video. No-op on iOS/macOS (TOS / existing cascade).
    func scheduleTVOSHighResOverlay(for video: Video) {
        #if os(tvOS)
        if tvosHighResOverlayVideoId == video.id { return }
        tvosHighResOverlayVideoId = video.id
        tvosHighResOverlayTask?.cancel()
        tvosHighResOverlayTask = Task { [weak self] in
            await self?.fetchTVOSHighResOverlay(for: video)
        }
        #endif
    }

    /// Reloads TVAuth/VisionOS HLS after a 1440p/2160p composition fails.
    func revertHighResOverlayToHLS(seekTo: TimeInterval) async {
        playerLog.notice("[tvOS-4K] overlay play failed — reverting to HLS")
        qualityManager.selectedFormat = nil
        qualityManager.pendingQualityLabel = ""
        isQualityChangePending = false
        toastMessage = "4K unavailable — using HLS"
        if statsForNerdsVisible { updateStatsSnapshot() }
        if playerInfo?.hlsURL != nil {
            await qualityManager.reloadHLSItem(seekTo: seekTo, quality: .auto)
        }
    }

    func revertHighResOverlayToHLSIfNeeded(seekTo: TimeInterval) async -> Bool {
        guard qualityManager.shouldFallbackHighResOverlayToHLS else { return false }
        await revertHighResOverlayToHLS(seekTo: seekTo)
        return true
    }

    #if os(tvOS)
    private func fetchTVOSHighResOverlay(for video: Video) async {
        guard !Task.isCancelled, currentVideo?.id == video.id else { return }

        var overlay: PlayerInfo?
        if hasAuthToken {
            overlay = await highResOverlayInfo(
                from: { try await self.api.fetchPlayerInfoWebCreator(videoId: video.id) },
                label: "WebCreator"
            )
        }
        if overlay == nil {
            overlay = await highResOverlayInfo(
                from: { try await self.api.fetchPlayerInfoAndroid(videoId: video.id) },
                label: "Android"
            )
        }
        guard !Task.isCancelled, currentVideo?.id == video.id else { return }
        guard let overlay else {
            playerLog.notice("[tvOS-4K] no playable 1440p/2160p overlay for \(video.id)")
            return
        }

        qualityManager.highResOverlayInfo = overlay
        // Re-assign so @Observable publishes the merged picker (getter adds overlay rows).
        availableFormats = qualityManager.availableFormats
        let heights = TVOSPlaybackPolicy.playableHighResFormats(from: overlay.formats).map(\.height)
        playerLog.notice(
            "[tvOS-4K] overlay applied heights=\(heights) pickerMax=\(availableFormats.map(\.height).max() ?? 0)"
        )

        autoSelectHighResOverlayIfPreferred()
    }

    private func highResOverlayInfo(
        from fetch: () async throws -> PlayerInfo,
        label: String
    ) async -> PlayerInfo? {
        do {
            let info = try await fetch()
            guard info.bestAdaptiveAudioURL != nil else {
                playerLog.notice("[tvOS-4K] \(label) has no adaptive AAC — skip")
                return nil
            }
            let high = TVOSPlaybackPolicy.playableHighResFormats(from: info.formats)
            playerLog.notice(
                "[tvOS-4K] \(label) formats=\(info.formats.count) playableHighRes=\(high.map(\.height))"
            )
            return high.isEmpty ? nil : info
        } catch {
            playerLog.notice("[tvOS-4K] \(label) fetch failed: \(error)")
            return nil
        }
    }

    /// When the user (or persisted default) asked for 1440p/2160p, switch off HLS
    /// onto the overlay once it is ready. Auto stays on HLS ABR.
    func autoSelectHighResOverlayIfPreferred() {
        guard let cap = effectiveQuality.maxHeight, cap >= TVOSPlaybackPolicy.highResMinHeight else {
            return
        }
        guard isPlaying, playerInfo?.hlsURL != nil else { return }
        let candidates = qualityManager.playableOverlayFormats.filter { $0.height <= cap }
        guard let fmt = candidates.first else { return }
        playerLog.notice("[tvOS-4K] auto-selecting overlay \(fmt.height)p (preferred cap \(cap)p)")
        selectFormat(fmt)
    }
    #endif
}
