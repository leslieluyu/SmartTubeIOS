import Foundation
import SmartTubeIOSCore

/// Testable tvOS playback decisions extracted from `PlaybackViewModel` so cold-start
/// quality, ABR hints, and the quality picker can be verified without AVPlayer.
///
/// Hypotheses this encodes (verified against the current call sites):
/// - **H1** Authenticated Apple TV sessions should start with TVHTML5 (`TVAuth`) HLS,
///   not the unauthenticated iOS client. The iOS client often returns no HLS or
///   `rqh=1` streams that fail in AVPlayer, which dumps the user into
///   `exhaustiveRetry` → muxed 360p ("Using fallback stream…").
/// - **H2** tvOS should not apply the iOS 360p fast-start ABR cap. Living-room
///   networks can sustain HD immediately; starting at 360p is the poor-quality
///   report. Use `effectiveQuality` (per-video pick, else `preferredQuality`).
/// - **H3** Muxed fallback must not shrink a richer format list — that hides
///   ⋯ → Quality (#139).
/// - **H4** When HLS variants exist but `PlayerInfo.formats` don't share those
///   heights (common for TVHTML5: HLS present, adaptive entries empty/SABR),
///   synthesize picker rows from the variant map.
/// - **H5** tvOS 1440p/2160p is an overlay: keep TVAuth HLS for cold start, merge
///   AVPlayer-decodable progressive formats from Android/WebCreator into the picker,
///   and play those via AVMutableComposition. HLS remains the fallback.
enum TVOSPlaybackPolicy {

    /// Signed-in Apple TV should prefer the authenticated TVHTML5 player response.
    static func prefersAuthenticatedTVClient(hasAuthToken: Bool) -> Bool {
        hasAuthToken
    }

    /// Height to apply as `preferredMaximumResolution` when first installing an HLS item.
    /// `skipFastStartCap == true` on tvOS: honour `effectiveQuality` immediately
    /// (`nil` = Auto / unconstrained). Otherwise return 360 for the iOS fast-start path.
    static func initialABRHeight(
        effectiveQuality: AppSettings.VideoQuality,
        skipFastStartCap: Bool
    ) -> Int? {
        if skipFastStartCap {
            return effectiveQuality.maxHeight
        }
        return 360
    }

    /// Muxed fallback must not replace a richer picker list with 360p-only entries.
    static func formatsAfterMuxedFallback(
        current: [VideoFormat],
        incoming: [VideoFormat]
    ) -> [VideoFormat] {
        if current.isEmpty { return incoming }
        let currentMax = current.map(\.height).max() ?? 0
        let incomingMax = incoming.map(\.height).max() ?? 0
        if incomingMax > currentMax || incoming.count > current.count {
            return incoming
        }
        return current
    }

    /// Build picker entries from HLS variant heights when player formats are empty
    /// or don't overlap the manifest.
    static func formatsFromHLSVariants(_ variants: [Int: URL]) -> [VideoFormat] {
        variants.keys.sorted(by: >).map { height in
            VideoFormat(
                label: "\(height)p",
                width: height * 16 / 9,
                height: height,
                fps: 30,
                mimeType: "video/mp4; codecs=\"avc1.640028\"",
                url: variants[height],
                bitrate: nil
            )
        }
    }

    /// Prefer real `PlayerInfo` formats that match HLS variant heights; otherwise
    /// synthesize rows so the quality picker stays usable.
    ///
    /// Playable progressive 1440p/2160p rows (Android / WebCreator overlay) are
    /// kept even when the HLS ladder stops at 1080p. SABR / rqh=1 / VP9 rows are
    /// not — those cannot play in AVPlayer.
    static func mergedHLSPickerFormats(
        existing: [VideoFormat],
        variants: [Int: URL]
    ) -> [VideoFormat] {
        guard !variants.isEmpty else { return existing }
        let matched = existing.filter { variants.keys.contains($0.height) }
        let hlsRows = matched.isEmpty ? formatsFromHLSVariants(variants) : matched
        return mergeHighResOverlay(hlsPicker: hlsRows, overlayFormats: existing)
    }

    /// Minimum height treated as "above the TVHTML5 HLS ladder" (typically 1080p).
    static let highResMinHeight = 1440

    /// SABR (`c=TVHTML5`) and `rqh=1` URLs are not AVPlayer-playable without BotGuard.
    static func isRestrictedStreamURL(_ url: URL) -> Bool {
        let s = url.absoluteString
        if s.contains("c=TVHTML5") { return true }
        if s.contains("/rqh/1") || s.contains("rqh=1") { return true }
        return false
    }

    /// Progressive `video/mp4` that AVPlayer can decode: H.264, HEVC, or AV1.
    /// VP9/WebM is excluded — tvOS AVFoundation has no VP9 decoder.
    static func isAVPlayerDecodableProgressive(_ format: VideoFormat) -> Bool {
        guard format.height > 0,
            format.mimeType.hasPrefix("video/mp4"),
            !format.mimeType.contains(", "),
            let url = format.url, !isRestrictedStreamURL(url)
        else { return false }
        let mime = format.mimeType
        return mime.contains("avc1") || mime.contains("hvc1") || mime.contains("hev1")
            || mime.contains("av01")
    }

    /// 1440p / 2160p progressive formats safe to offer on the tvOS quality picker.
    static func playableHighResFormats(from formats: [VideoFormat]) -> [VideoFormat] {
        formats.filter { isAVPlayerDecodableProgressive($0) && $0.height >= highResMinHeight }
            .sorted { lhs, rhs in
                if lhs.height != rhs.height { return lhs.height > rhs.height }
                if lhs.fps != rhs.fps { return lhs.fps > rhs.fps }
                let rank: (VideoFormat) -> Int = { fmt in
                    if fmt.mimeType.contains("avc1") { return 0 }
                    if fmt.mimeType.contains("hvc1") || fmt.mimeType.contains("hev1") { return 1 }
                    return 2
                }
                let lRank = rank(lhs)
                let rRank = rank(rhs)
                if lRank != rRank { return lRank < rRank }
                return (lhs.bitrate ?? 0) > (rhs.bitrate ?? 0)
            }
    }

    /// Overlay 1440p/2160p progressive rows onto an HLS picker that tops out at 1080p.
    /// Heights present in the overlay replace any SABR/unplayable picker row at that height.
    static func mergeHighResOverlay(
        hlsPicker: [VideoFormat],
        overlayFormats: [VideoFormat]
    ) -> [VideoFormat] {
        let overlay = playableHighResFormats(from: overlayFormats)
        guard !overlay.isEmpty else { return hlsPicker }
        let overlayHeights = Set(overlay.map(\.height))
        let kept = hlsPicker.filter { !overlayHeights.contains($0.height) }
        return overlay + kept
    }

    /// Selecting 1440p/2160p that exists only in the progressive overlay must not
    /// go through HLS ABR hints — the TVAuth/VisionOS ladder has no such variants.
    static func usesProgressiveHighResPath(
        height: Int?,
        hlsVariantHeights: Set<Int>,
        overlayHeights: Set<Int>
    ) -> Bool {
        guard let height, height >= highResMinHeight else { return false }
        guard overlayHeights.contains(height) else { return false }
        return !hlsVariantHeights.contains(height)
    }
}
