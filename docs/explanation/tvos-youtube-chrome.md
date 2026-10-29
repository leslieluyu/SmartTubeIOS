> status: current — 2026-10-29

# tvOS YouTube-like chrome

Approximates official YouTube on Apple TV for **in-player controls**, **Home**, and the
**left navigation rail**. Does not reverse-engineer the closed YouTube app; layout follows
the user’s requested chrome plus in-repo player/home building blocks.

4K progressive overlay and Siri Remote Select restore (`TVOSPlayerFocusPolicy`) are unchanged.

## Approximated

| Surface | What we match |
|---|---|
| **Player bar** | Bottom of the video (not floating centre chrome). Title + description + Subscribe. Left/Right seek while Play/Pause is the centre action. Like, Dislike, Comments, Save (Watch Later), Options (⋯). |
| **Home** | Large Recommended hero at the top, then Recommended / Shorts / Subscriptions shelves. |
| **Left rail** | Collapsed icon stack; expands with labels when focused. Search, Home, Subscriptions, Library, News, Gaming, Live, Music, Sports, Settings. Compact metrics (`TVOSSidebarMetrics`) keep 12 destinations readable without overlap on Apple TV 1080p. |

## Missing / stubbed

| Item | Why |
|---|---|
| **Podcasts, Movies** | No in-app feed. Rail still lists them; the page is an empty “not available yet” state. |
| **YouTube-account Subscribe** | Channel follow uses `LocalSubscriptionStore` (same as unsigned ChannelView Follow). Signed-in InnerTube `subscription/subscribe` is deferred. |
| **Save status from other clients** | Watch Later membership is local to this app (`WatchLaterMembershipStore`). |
| **Hero autoplay / ambient preview** | Thumbnail + metadata only; no background playback of the focused tile. |
| **Continue watching / named InnerTube shelves** | Home still flattens `fetchHomeRows` for iOS; tvOS rebuilds Recommended + Subscriptions shelves from those sections rather than every named TVHTML5 row. |

## Deferred

- Native YouTube-account subscribe/unsubscribe and subscribe-state from `/next`.
- Movies & Podcasts browse IDs if InnerTube ever exposes a TOS-safe TV client feed.
- Replacing software player highlight (`TVOSPlayerControl`) with SwiftUI focus on the chrome buttons (would fight the 4K Select restore).

## Code

- Player policy: `TVOSPlayerControlPolicy`
- Bottom bar: `PlayerControlsOverlay.tvosBottomChrome` (`PlayerView+tvOS.swift`)
- Home hero: `TVOSHomeHeroView`, `HomeViewModel.featuredHeroVideo`
- Rail: `TVOSSidebarDestination`, `TVOSSidebarView`, `MainTVTabView`
