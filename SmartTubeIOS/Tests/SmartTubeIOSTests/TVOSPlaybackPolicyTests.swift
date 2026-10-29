import AVFoundation
import Foundation
import Testing

@testable import SmartTubeIOS
@testable import SmartTubeIOSCore

@Suite("tvOS playback quality policy")
struct TVOSPlaybackPolicyTests {

    private func makeFormat(
        height: Int,
        muxed: Bool = false,
        mimeType: String? = nil,
        url: String? = nil
    ) -> VideoFormat {
        VideoFormat(
            label: "\(height)p",
            width: height * 16 / 9,
            height: height,
            fps: 30,
            mimeType: mimeType
                ?? (muxed
                    ? "video/mp4; codecs=\"avc1.42001E, mp4a.40.2\""
                    : "video/mp4; codecs=\"avc1.640028\""),
            url: URL(string: url ?? "https://example.com/\(height).mp4"),
            bitrate: height * 1_000
        )
    }

    // MARK: - H1 cold-start client

    @Test("authenticated session prefers TVAuth on cold start")
    func prefersTVAuthWhenSignedIn() {
        #expect(TVOSPlaybackPolicy.prefersAuthenticatedTVClient(hasAuthToken: true))
    }

    @Test("signed-out session does not force TVAuth")
    func doesNotPreferTVAuthWhenSignedOut() {
        #expect(!TVOSPlaybackPolicy.prefersAuthenticatedTVClient(hasAuthToken: false))
    }

    // MARK: - H2 ABR hints / preferredQuality

    @Test("tvOS skips 360p fast-start and uses preferredQuality")
    func tvOSInitialABRHonoursPreferredQuality() {
        #expect(
            TVOSPlaybackPolicy.initialABRHeight(effectiveQuality: .q1080, skipFastStartCap: true)
                == 1080)
        #expect(
            TVOSPlaybackPolicy.initialABRHeight(effectiveQuality: .q2160, skipFastStartCap: true)
                == 2160)
        #expect(
            TVOSPlaybackPolicy.initialABRHeight(effectiveQuality: .auto, skipFastStartCap: true)
                == nil)
    }

    @Test("iOS fast-start still caps at 360p")
    func iosFastStartStays360() {
        #expect(
            TVOSPlaybackPolicy.initialABRHeight(effectiveQuality: .q1080, skipFastStartCap: false)
                == 360)
        #expect(
            TVOSPlaybackPolicy.initialABRHeight(effectiveQuality: .auto, skipFastStartCap: false)
                == 360)
    }

    // MARK: - H3 muxed fallback must not wipe the picker

    @Test("muxed 360p does not replace a richer format list")
    func muxedFallbackKeepsRicherFormats() {
        let current = [makeFormat(height: 1080), makeFormat(height: 720)]
        let muxed = [makeFormat(height: 360, muxed: true)]
        let kept = TVOSPlaybackPolicy.formatsAfterMuxedFallback(current: current, incoming: muxed)
        #expect(kept.map(\.height) == [1080, 720])
    }

    @Test("muxed formats are used when the picker is still empty")
    func muxedFallbackFillsEmptyPicker() {
        let muxed = [makeFormat(height: 360, muxed: true)]
        let kept = TVOSPlaybackPolicy.formatsAfterMuxedFallback(current: [], incoming: muxed)
        #expect(kept.map(\.height) == [360])
    }

    @Test("richer incoming muxed-path formats still win")
    func richerIncomingFormatsReplace() {
        let current = [makeFormat(height: 360, muxed: true)]
        let incoming = [makeFormat(height: 1080), makeFormat(height: 720), makeFormat(height: 360)]
        let kept = TVOSPlaybackPolicy.formatsAfterMuxedFallback(current: current, incoming: incoming)
        #expect(kept.map(\.height) == [1080, 720, 360])
    }

    // MARK: - H4 synthesize picker from HLS variants (#139)

    @Test("empty player formats get synthetic HLS picker rows")
    func synthesizesFormatsFromVariants() {
        let variants: [Int: URL] = [
            1080: URL(string: "https://example.com/1080.m3u8")!,
            720: URL(string: "https://example.com/720.m3u8")!,
            360: URL(string: "https://example.com/360.m3u8")!,
        ]
        let formats = TVOSPlaybackPolicy.mergedHLSPickerFormats(existing: [], variants: variants)
        #expect(formats.map(\.height) == [1080, 720, 360])
        #expect(formats.allSatisfy { $0.url != nil })
    }

    @Test("matching player formats are kept; non-overlapping heights are synthesized")
    func prefersMatchingFormatsThenSynthesizes() {
        let existing = [makeFormat(height: 1080), makeFormat(height: 480)]
        let variants: [Int: URL] = [
            1080: URL(string: "https://example.com/1080.m3u8")!,
            720: URL(string: "https://example.com/720.m3u8")!,
        ]
        let matched = TVOSPlaybackPolicy.mergedHLSPickerFormats(
            existing: existing, variants: variants)
        #expect(matched.map(\.height) == [1080], "only heights present in the manifest are kept")

        let sabrOnly = [
            makeFormat(
                height: 2160,
                url: "https://rr1.googlevideo.com/videoplayback?itag=313&c=TVHTML5")
        ]
        let synthesized = TVOSPlaybackPolicy.mergedHLSPickerFormats(
            existing: sabrOnly, variants: variants)
        #expect(
            synthesized.map(\.height) == [1080, 720],
            "SABR 2160p is not kept; synthesize HLS rows from variants")

        let playable4K = [
            makeFormat(
                height: 2160,
                mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
                url: "https://rr1.googlevideo.com/videoplayback?itag=401&c=ANDROID")
        ]
        let withOverlay = TVOSPlaybackPolicy.mergedHLSPickerFormats(
            existing: playable4K, variants: variants)
        #expect(
            withOverlay.map(\.height) == [2160, 1080, 720],
            "playable progressive 2160p is kept beside the HLS ladder")
    }

    // MARK: - HLSPlaybackPolicy client UA (#139 / TVAuth)

    @Test("TVAuth HLS uses the TV Cobalt UA and does not cap or force H.264")
    func tvAuthPolicy() {
        let policy = HLSPlaybackPolicy.resolve(label: "TVAuth[1]/HLS", isHLS: true)
        #expect(policy.userAgent == InnerTubeClients.TV.userAgent)
        #expect(policy.maximumHeight == nil)
        #expect(!policy.filtersMasterManifest)
        #expect(!policy.requiresH264)
        #expect(policy.cappedHeight(requested: 2160) == 2160)
        #expect(policy.cappedHeight(requested: nil) == nil)
        #expect(
            policy.allowsFormat(
                height: 2160, mimeType: "video/mp4; codecs=\"hvc1.1.6.L150.B0\""))
    }

    @Test("cold-start TVAuth label matches the same policy")
    func tvAuthColdStartLabel() {
        let policy = HLSPlaybackPolicy.resolve(label: "TVAuth/HLS", isHLS: true)
        #expect(policy.userAgent == InnerTubeClients.TV.userAgent)
    }

    @Test("TVEmbedded HLS uses the WEB embed UA without a height cap")
    func tvEmbeddedPolicy() {
        let policy = HLSPlaybackPolicy.resolve(label: "TVEmbedded[1]/HLS", isHLS: true)
        #expect(policy.userAgent == InnerTubeClients.Web.userAgent)
        #expect(policy.maximumHeight == nil)
        #expect(!policy.requiresH264)
    }

    @Test("MWEB HLS uses the MWEB UA")
    func mwebPolicy() {
        let policy = HLSPlaybackPolicy.resolve(label: "MWEB[1]/HLS", isHLS: true)
        #expect(policy.userAgent == InnerTubeClients.MWEB.userAgent)
        #expect(policy.maximumHeight == nil)
    }

    @Test("VisionOS and WebSafari policies stay unchanged")
    func existingPoliciesUnchanged() {
        let vision = HLSPlaybackPolicy.resolve(label: "VisionOS/HLS", isHLS: true)
        #expect(vision.userAgent == InnerTubeClients.VisionOS.userAgent)
        #expect(vision.requiresH264)
        #expect(vision.maximumHeight == InnerTubeClients.VisionOS.maximumHLSHeight)

        let safari = HLSPlaybackPolicy.resolve(label: "WebSafari[1]/HLS", isHLS: true)
        #expect(safari.userAgent == InnerTubeClients.WebSafari.userAgent)
        #expect(safari.maximumHeight == nil)
    }

    // MARK: - H5 tvOS 1440p/2160p overlay

    @Test("AV1/HEVC/H.264 progressive 4K is playable; VP9, SABR, and rqh=1 are not")
    func playableHighResFilter() {
        let av1 = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=401&c=ANDROID")
        let hevc = makeFormat(
            height: 1440, mimeType: "video/mp4; codecs=\"hvc1.1.6.L150.B0\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=266&c=ANDROID")
        let vp9 = makeFormat(
            height: 2160, mimeType: "video/webm; codecs=\"vp09.00.51.08\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=313&c=ANDROID")
        let vp9InMp4 = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"vp09.00.51.08\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=313&c=ANDROID")
        let sabr = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=401&c=TVHTML5")
        let rqh = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
            url: "https://rr1.googlevideo.com/videoplayback/rqh/1/video.mp4?itag=401&c=ANDROID")
        let h2641080 = makeFormat(height: 1080)

        #expect(TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(av1))
        #expect(TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(hevc))
        #expect(!TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(vp9))
        #expect(!TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(vp9InMp4))
        #expect(!TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(sabr))
        #expect(!TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(rqh))
        #expect(TVOSPlaybackPolicy.isAVPlayerDecodableProgressive(h2641080))

        let high = TVOSPlaybackPolicy.playableHighResFormats(from: [
            av1, hevc, vp9, sabr, rqh, h2641080,
        ])
        #expect(high.map(\.height) == [2160, 1440])
        #expect(high[0].codecShortLabel == "AV1")
        #expect(high[1].codecShortLabel == "HEVC")
    }

    @Test("overlay merge puts 2160p/1440p above the HLS 1080p ladder")
    func mergeHighResOverlayOntoHLSPicker() {
        let hls = [
            makeFormat(height: 1080),
            makeFormat(height: 720),
            makeFormat(height: 360),
        ]
        let overlay = [
            makeFormat(
                height: 2160, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
                url: "https://rr1.googlevideo.com/videoplayback?itag=401&c=ANDROID"),
            makeFormat(
                height: 1440, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
                url: "https://rr1.googlevideo.com/videoplayback?itag=400&c=ANDROID"),
            makeFormat(height: 1080),
        ]
        let merged = TVOSPlaybackPolicy.mergeHighResOverlay(hlsPicker: hls, overlayFormats: overlay)
        #expect(merged.map(\.height) == [2160, 1440, 1080, 720, 360])
        #expect(merged[0].codecShortLabel == "AV1")
        #expect(merged[2].url?.absoluteString.contains("example.com") == true)
    }

    @Test("4K selection uses progressive composition, not HLS ABR, when HLS has no 2160p")
    func usesProgressivePathWhenHLSLacks4K() {
        #expect(
            TVOSPlaybackPolicy.usesProgressiveHighResPath(
                height: 2160, hlsVariantHeights: [1080, 720, 360], overlayHeights: [2160, 1440]))
        #expect(
            TVOSPlaybackPolicy.usesProgressiveHighResPath(
                height: 1440, hlsVariantHeights: [1080, 720], overlayHeights: [2160, 1440]))
        #expect(
            !TVOSPlaybackPolicy.usesProgressiveHighResPath(
                height: 1080, hlsVariantHeights: [1080, 720], overlayHeights: [2160, 1440]))
        #expect(
            !TVOSPlaybackPolicy.usesProgressiveHighResPath(
                height: 2160, hlsVariantHeights: [2160, 1080], overlayHeights: [2160]))
        #expect(
            !TVOSPlaybackPolicy.usesProgressiveHighResPath(
                height: 2160, hlsVariantHeights: [1080], overlayHeights: []))
        #expect(
            !TVOSPlaybackPolicy.usesProgressiveHighResPath(
                height: nil, hlsVariantHeights: [1080], overlayHeights: [2160]))
    }

    @Test("H.264 ranks ahead of AV1 at the same 4K height")
    func highResPrefersH264ThenHEVCThenAV1() {
        let av1 = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=401&c=ANDROID")
        let h264 = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"avc1.640033\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=266&c=ANDROID")
        let ranked = TVOSPlaybackPolicy.playableHighResFormats(from: [av1, h264])
        #expect(ranked.map(\.codecShortLabel) == ["H.264", "AV1"])
    }

    @Test("4K overlay DASH failure falls back to HLS instead of 403 recovery")
    @MainActor
    func overlayDASHFailureFallsBackToHLS() {
        let player = OverlayMockPlayer()
        let mgr = PlaybackQualityManager(player: player)
        let delegate = OverlayMockDelegate()
        delegate.playerInfo = PlayerInfo(
            video: Video(id: "vid", title: "T", channelTitle: "C"),
            formats: [makeFormat(height: 1080)],
            hlsURL: URL(string: "https://example.com/master.m3u8"),
            dashURL: nil,
            captionTracks: [],
            trackingURLs: nil,
            endCards: []
        )
        mgr.delegate = delegate
        mgr.hlsVariantURLs = [1080: URL(string: "https://example.com/1080.m3u8")!]
        let av1 = makeFormat(
            height: 2160, mimeType: "video/mp4; codecs=\"av01.0.12M.08\"",
            url: "https://rr1.googlevideo.com/videoplayback?itag=401&c=ANDROID")
        mgr.highResOverlayInfo = PlayerInfo(
            video: Video(id: "vid", title: "T", channelTitle: "C"),
            formats: [av1],
            hlsURL: nil,
            dashURL: nil,
            captionTracks: [],
            trackingURLs: nil,
            endCards: []
        )
        mgr.selectedFormat = av1
        #expect(mgr.shouldFallbackHighResOverlayToHLS)

        mgr.selectedFormat = makeFormat(height: 1080)
        #expect(!mgr.shouldFallbackHighResOverlayToHLS)
    }
}

private final class OverlayMockPlayer: PlayerItemSwappable {
    var rate: Float = 0
    func replaceCurrentItem(with item: AVPlayerItem?) {}
}

@MainActor
private final class OverlayMockDelegate: QualityContext, QualityEventHandler {
    var playerInfo: PlayerInfo?
    var settings = AppSettings()
    var currentVideo: Video?
    var currentTime: TimeInterval = 0
    var toastMessage: String?
    var isSwappingItem = false
    var isQualityChangePending = false
    func qualityItemDidBecomeReady(_ item: AVPlayerItem, seekTo: TimeInterval) {}
    func qualityItemDidFail(error: Error?, quality: AppSettings.VideoQuality, hasAppliedH264Cap: Bool) async {}
    func qualitySelectDASHFormat(videoURL: URL, audioURL: URL, seekTo: TimeInterval) async {}
}
