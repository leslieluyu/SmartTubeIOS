> status: current — 2026-10-29

# tvOS 4K (1440p / 2160p)

Signed-in Apple TV cold-start still uses authenticated TVHTML5 (`TVAuth`) HLS → AVPlayer.
That ladder is typically **1080p HEVC/H.264**. Official YouTube on Apple TV reaches 4K via a
private VP9/AV1/SABR stack we do not copy.

## What this app does

After HLS is playing, tvOS fetches a **progressive overlay** from InnerTube clients that
historically return real HTTPS URLs above 1080p:

1. **WebCreator** (signed-in) — rqh-exempt adaptive `video/mp4`, 720p–2160p when SAPISID or
   Bearer+`X-Goog-AuthUser` is accepted.
2. **Android** — unauthenticated adaptive URLs up to 4K in prior probes; often
   `LOGIN_REQUIRED` (“Sign in to confirm you’re not a bot”) from datacenter IPs.

Playable overlay rows (1440p / 2160p) are merged into the quality picker. Selecting one
rebuilds an **`AVMutableComposition`** (video-only + AAC audio) and hands it to **AVPlayer**.
If that composition fails (403, timeout, cannot decode), the original **HLS 1080p** item is
reloaded. Auto quality stays on HLS ABR.

## Limitations

| Topic | Reality |
|---|---|
| **Player** | AVPlayer only. There is no in-repo VP9/SABR decoder. |
| **Codec** | Overlay offers `avc1` / `hvc1` / `av01` in `video/mp4`. YouTube 4K is usually **AV1 or VP9**. VP9/WebM is never listed (AVFoundation cannot decode it on tvOS). AV1 needs Apple TV 4K (2nd gen, 2021+) hardware; the Simulator cannot decode AV1/VP9. H.264 4K (itag 266) is rare. |
| **SABR** | TVHTML5 adaptive URLs (`c=TVHTML5`) and `serverAbrStreamingUrl` are skipped. They are UMP, not MP4. |
| **Auth / BotGuard** | tvOS has no WKWebView BotGuard recovery. `rqh=1` URLs are skipped (`docs/explanation/no-botguard.md`). WebCreator may 400 with TV OAuth Bearer (it prefers SAPISIDHASH). Android may be bot-gated. Overlay failure does **not** replace TVAuth HLS. |
| **VisionOS HLS** | Intentional 1080 H.264 cap; not used as the 4K path. |
| **Remote / focus** | Overlay apply and composition item swaps can drop SwiftUI `@FocusState`. The player re-asserts Siri Remote focus when no overlay is open (`TVOSPlayerFocusPolicy`). Overlay dimmers are not focusable on tvOS (Menu/Back dismisses). Remaining: Simulator cannot decode AV1, so focus-after-4K-swap is device-only; skip-toast still takes Select while a SponsorBlock prompt is visible. |

## Code

- Policy: `TVOSPlaybackPolicy` (`highResMinHeight`, `playableHighResFormats`, `usesProgressiveHighResPath`)
- Focus: `TVOSPlayerFocusPolicy` (when the player body may reclaim Select vs an open overlay)
- Fetch: `PlaybackViewModel+TVOSHighRes.swift`
- Play: `PlaybackQualityManager.selectFormat` → DASH composition when the height is overlay-only
