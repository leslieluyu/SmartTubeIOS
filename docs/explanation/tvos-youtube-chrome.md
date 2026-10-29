> status: current — 2026-10-29

# tvOS YouTube-like chrome

Approximates official YouTube on Apple TV for **in-player remote behaviour**, **in-player
controls**, **Home**, and the **left navigation rail**. Does not reverse-engineer the closed
YouTube app; layout follows the user’s requested chrome plus in-repo player/home building
blocks.

4K progressive overlay and Siri Remote Select restore (`TVOSPlayerFocusPolicy`) are unchanged.

## Remote map (in-player)

Software highlight (`TVOSPlayerControl`) owns Select. Native focus stays on the player body
so a 4K composition item swap can re-assert it (`TVOSPlayerFocusPolicy`).

### A — Chrome hidden (fullscreen)

| Remote | Action |
|---|---|
| **Left / Right** | Seek (relative, `seekBackSeconds` / `seekForwardSeconds`) |
| **Select** | Show the bottom control bar; software focus on **Play/Pause** (does not toggle playback) |
| **Down** | Same as Select: show the bar on **Play/Pause** |
| **Up** | Show the bar with the **scrubber** highlighted |

Seek is gated on chrome-hidden. Play/Pause is not a seek target while the bar is up.

### B — Chrome visible

| Remote | Action |
|---|---|
| Focus default | **Play/Pause** |
| **Up** | Highlight the scrubber / progress bar |
| **Left / Right** on bottom icons | Move among **prev · −N s · play/pause · +N s · next · like · dislike · comments · save · options**. No seek. |
| **Left / Right** on the scrubber | Timeline nudge (the one chrome-visible seek exception) |
| **Down** from the scrubber | Return to **Play/Pause** |
| **Up** from the scrubber | Channel / Subscribe (info row) |
| **Select** on a highlighted icon | Activate that control (Play/Pause toggles playback; ± seek icons seek) |

### Bottom-chrome software-focus ring

Native focus stays on the player body. The software highlight (`highlightedControl`) is the
only focus ring. Every control rendered on the bottom chrome:

| Control | Rendered | In L/R ring | Software highlight | Select |
|---|---|---|---|---|
| Title / description | yes | no (labels) | no | n/a |
| Channel name | yes (info row) | channel ↔ subscribe | yes | open channel |
| Subscribe | yes (info row) | channel ↔ subscribe | yes | follow / unfollow |
| Current chapter | yes, if chapters | no (label) | no | n/a |
| Scrubber / progress | yes | Up from any bottom icon | yes | toggle play/pause |
| Previous video | yes | yes | yes | previous in queue |
| **Rewind −N s** | yes | **yes** (left of Play) | **yes** | relative seek back |
| Play / Pause | yes | yes (default) | yes | toggle play/pause |
| **Forward +N s** | yes | **yes** (right of Play) | **yes** | relative seek forward |
| Next video | yes | yes | yes | next in queue |
| Like | yes | yes | yes | like |
| Dislike | yes | yes | yes | dislike |
| Comments | yes | yes | yes | comments sheet |
| Save (Watch Later) | yes | yes | yes | toggle Watch Later |
| Options (⋯) | yes | yes | yes | right settings drawer |

There is no separate Settings gear or CC glyph on this strip; captions, quality, speed,
audio, and sleep live in the Options drawer. Captions/CC are not missing from the ring —
they are not drawn on the bar.

Rewind / forward used to be drawn with `tvHighlighted: false` and omitted from
`TVOSPlayerControlPolicy.bottomIcons` (visual affordances only). They are first-class
neighbors of Play/Pause.

## Approximated

| Surface | What we match |
|---|---|
| **Fullscreen playback** | While `PlayerView` is on screen the left rail is collapsed to zero width, disabled, and hidden from accessibility (`TVOSPlaybackPresentation`). It stays in the `HStack` so the `NavigationStack` is not reset. Back / Menu pops the player and the rail returns. |
| **Player bar** | Bottom of the video (not floating centre chrome). Title + description + Subscribe. Transport uses dense 1080p metrics (`TVOSPlayerChromeMetrics`: ~52pt play/pause, ~40pt actions). |
| **Remote (Mode A / B)** | `TVOSPlayerControlPolicy.outcome` — seek only while chrome is hidden (and on the highlighted scrubber). |
| **Settings / options** | Opaque right-side drawer (~360pt, leading edge, `player.settingsPanel`) over **fullscreen dimmed video**. Quality, speed, captions, audio track, and sleep timer pickers use the same trailing panel, dense row fonts, and no default tvOS focus platter. |
| **Home** | Recommended carousel of large 16:9 cards (~2.5 visible), then Shorts / Subscriptions (~3.5-across). Focused card uses a white/red border and slight scale. Duration bottom-right; 4K/HDR badges top-right when InnerTube sends them. |
| **Left rail** | Collapsed icon stack; expands with labels when focused. Search, Home, Subscriptions, Library, News, Gaming, Live, Music, Sports, Settings. Medium 1080p metrics (`TVOSSidebarMetrics`: ~30pt icons, ~26pt labels, fixed row spacing). Focused row owns the white pill; the current page uses a dimmer selected state. Hidden during playback. |

## Missing / stubbed

| Item | Why |
|---|---|
| **Podcasts, Movies** | No in-app feed. Rail still lists them; the page is an empty “not available yet” state. |
| **YouTube-account Subscribe** | Channel follow uses `LocalSubscriptionStore` (same as unsigned ChannelView Follow). Signed-in InnerTube `subscription/subscribe` is deferred. |
| **Save status from other clients** | Watch Later membership is local to this app (`WatchLaterMembershipStore`). |
| **Focused-card autoplay / ambient preview** | Thumbnail + metadata only; no background playback of the focused tile. |
| **Continue watching / named InnerTube shelves** | Home still flattens `fetchHomeRows` for iOS; tvOS rebuilds Recommended + Subscriptions shelves from those sections rather than every named TVHTML5 row. |

## Deferred

- Native YouTube-account subscribe/unsubscribe and subscribe-state from `/next`.
- Movies & Podcasts browse IDs if InnerTube ever exposes a TOS-safe TV client feed.
- Replacing software player highlight (`TVOSPlayerControl`) with SwiftUI focus on the chrome buttons (would fight the 4K Select restore).
- Comments and description stay bottom sheets (in-repo overlay stack); not a YouTube TV right-rail comments column.
- Nested settings (quality list replacing the parent menu in-place) — pickers currently replace the options panel as a second trailing drawer.
- Player is still a `NavigationStack` destination (channel can push on top); it is not a separate window-level `fullScreenCover` from Home. Collapsing the rail is what makes playback fullscreen.
- Official YouTube’s letterboxed video card + oversized quality pills. This app keeps the picture fullscreen behind a dim scrim and a narrow dense drawer.

## Code

- Playback presentation: `TVOSPlaybackPresentation`, `MainTVTabView`
- Player policy: `TVOSPlayerControlPolicy`
- Focus restore: `TVOSPlayerFocusPolicy`
- Chrome metrics: `TVOSPlayerChromeMetrics`
- Bottom bar: `PlayerControlsOverlay.tvosBottomChrome` (`PlayerView+tvOS.swift`)
- Settings panel: `PlayerView.moreMenuOverlay` / `PlayerOverlayPanelModifier` / `TVOSSettingsRowButtonStyle`
- Home shelves: `TVOSHomeShelfMetrics`, `HomeView.tvosHomeShelves`
- Rail: `TVOSSidebarDestination`, `TVOSSidebarView`, `MainTVTabView`
