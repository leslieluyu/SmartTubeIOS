> status: current — 2026-10-29

# tvOS YouTube-like chrome

Approximates official YouTube on Apple TV for **in-player controls**, **Home**, and the
**left navigation rail**. Does not reverse-engineer the closed YouTube app; layout follows
the user’s requested chrome plus in-repo player/home building blocks.

4K progressive overlay and Siri Remote Select restore (`TVOSPlayerFocusPolicy`) are unchanged.

## Approximated

| Surface | What we match |
|---|---|
| **Fullscreen playback** | While `PlayerView` is on screen the left rail is collapsed to zero width, disabled, and hidden from accessibility (`TVOSPlaybackPresentation`). It stays in the `HStack` so the `NavigationStack` is not reset. Back / Menu pops the player and the rail returns. |
| **Player bar** | Bottom of the video (not floating centre chrome). Title + description + Subscribe. Left/Right seek while Play/Pause is the centre action. Like, Dislike, Comments, Save (Watch Later), Options (⋯). Transport uses dense 1080p metrics (`TVOSPlayerChromeMetrics`: ~52pt play/pause, ~40pt actions). |
| **Settings / options** | Right-side drawer (~420pt, `player.settingsPanel`), not a full-width bottom strip. Quality, speed, captions, audio track, and sleep timer pickers use the same trailing panel. |
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

## Code

- Playback presentation: `TVOSPlaybackPresentation`, `MainTVTabView`
- Player policy: `TVOSPlayerControlPolicy`
- Chrome metrics: `TVOSPlayerChromeMetrics`
- Bottom bar: `PlayerControlsOverlay.tvosBottomChrome` (`PlayerView+tvOS.swift`)
- Settings panel: `PlayerView.moreMenuOverlay` / `PlayerOverlayPanelModifier`
- Home shelves: `TVOSHomeShelfMetrics`, `HomeView.tvosHomeShelves`
- Rail: `TVOSSidebarDestination`, `TVOSSidebarView`, `MainTVTabView`
