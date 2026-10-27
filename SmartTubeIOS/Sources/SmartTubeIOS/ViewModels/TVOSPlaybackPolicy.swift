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
    static func mergedHLSPickerFormats(
        existing: [VideoFormat],
        variants: [Int: URL]
    ) -> [VideoFormat] {
        guard !variants.isEmpty else { return existing }
        let matched = existing.filter { variants.keys.contains($0.height) }
        if !matched.isEmpty { return matched }
        return formatsFromHLSVariants(variants)
    }
}
