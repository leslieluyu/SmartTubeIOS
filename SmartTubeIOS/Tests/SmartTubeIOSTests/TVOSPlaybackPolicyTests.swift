import Foundation
import Testing

@testable import SmartTubeIOS
@testable import SmartTubeIOSCore

@Suite("tvOS playback quality policy")
struct TVOSPlaybackPolicyTests {

    private func makeFormat(height: Int, muxed: Bool = false) -> VideoFormat {
        VideoFormat(
            label: "\(height)p",
            width: height * 16 / 9,
            height: height,
            fps: 30,
            mimeType: muxed
                ? "video/mp4; codecs=\"avc1.42001E, mp4a.40.2\""
                : "video/mp4; codecs=\"avc1.640028\"",
            url: URL(string: "https://example.com/\(height).mp4"),
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

        let sabrOnly = [makeFormat(height: 2160)]
        let synthesized = TVOSPlaybackPolicy.mergedHLSPickerFormats(
            existing: sabrOnly, variants: variants)
        #expect(
            synthesized.map(\.height) == [1080, 720],
            "when no format height matches the manifest, synthesize from variants")
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
}
