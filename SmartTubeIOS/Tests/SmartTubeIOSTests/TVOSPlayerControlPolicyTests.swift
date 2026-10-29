import Foundation
import Testing

@testable import SmartTubeIOS

@Suite("tvOS YouTube-like player chrome navigation")
struct TVOSPlayerControlPolicyTests {

    @Test("play/pause is the transport control")
    func playPauseIsTransport() {
        #expect(TVOSPlayerControlPolicy.isTransport(.playPause))
        #expect(!TVOSPlayerControlPolicy.isTransport(.seekBack))
        #expect(!TVOSPlayerControlPolicy.isTransport(.seekForward))
        #expect(!TVOSPlayerControlPolicy.isTransport(.scrubber))
        #expect(!TVOSPlayerControlPolicy.isTransport(.like))
        #expect(TVOSPlayerControlPolicy.isBottomIcon(.playPause))
        #expect(TVOSPlayerControlPolicy.isBottomIcon(.seekBack))
        #expect(TVOSPlayerControlPolicy.isBottomIcon(.seekForward))
        #expect(!TVOSPlayerControlPolicy.isBottomIcon(.scrubber))
    }

    @Test("bottom icon ring is prev · −N s · play · +N s · next · actions")
    func bottomIconRingOrder() {
        #expect(
            TVOSPlayerControlPolicy.bottomIcons == [
                .prevVideo, .seekBack, .playPause, .seekForward, .nextVideo,
                .like, .dislike, .comments, .save, .more,
            ])
    }

    @Test("chrome hidden: left/right seek regardless of highlight")
    func hiddenChromeLeftRightSeek() {
        #expect(
            TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: false, control: nil, direction: .left))
        #expect(
            TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: false, control: .playPause, direction: .right))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: false, control: nil, direction: .down))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: false, control: nil, direction: .up))
    }

    @Test("chrome visible: play/pause left/right do not seek")
    func visibleChromePlayPauseDoesNotSeek() {
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .playPause, direction: .left))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .playPause, direction: .right))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .like, direction: .left))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .seekBack, direction: .left))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .seekForward, direction: .right))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: nil, direction: .right))
    }

    @Test("chrome visible: highlighted ± seek icons move, they do not D-pad seek")
    func visibleChromeSeekButtonsMoveNotSeek() {
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .seekBack, direction: .left)
                == .highlight(.prevVideo))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .seekBack, direction: .right)
                == .highlight(.playPause))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .seekForward, direction: .left)
                == .highlight(.playPause))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .seekForward, direction: .right)
                == .highlight(.nextVideo))
    }

    @Test("chrome visible: highlighted scrubber left/right still seek")
    func visibleChromeScrubberSeeks() {
        #expect(
            TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .scrubber, direction: .left))
        #expect(
            TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .scrubber, direction: .right))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                chromeVisible: true, control: .scrubber, direction: .up))
    }

    @Test("hidden chrome: down and select default to play/pause; up to scrubber")
    func hiddenChromeFocusDefaults() {
        #expect(TVOSPlayerControlPolicy.defaultChromeFocus == .playPause)
        #expect(TVOSPlayerControlPolicy.initialFocus(revealingWith: .down) == .playPause)
        #expect(TVOSPlayerControlPolicy.initialFocus(revealingWith: .up) == .scrubber)
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: false, highlighted: nil, direction: .down) == .highlight(.playPause))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: false, highlighted: nil, direction: .up) == .highlight(.scrubber))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: false, highlighted: nil, direction: .left) == .seek)
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: false, highlighted: nil, direction: .right) == .seek)
    }

    @Test("chrome visible: left/right walk bottom icons from play/pause")
    func visibleChromeWalksBottomIcons() {
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .playPause, direction: .left)
                == .highlight(.seekBack))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .playPause, direction: .right)
                == .highlight(.seekForward))
        #expect(TVOSPlayerControlPolicy.next(from: .seekBack, direction: .left) == .prevVideo)
        #expect(TVOSPlayerControlPolicy.next(from: .seekForward, direction: .right) == .nextVideo)
        #expect(TVOSPlayerControlPolicy.next(from: .nextVideo, direction: .right) == .like)
        #expect(TVOSPlayerControlPolicy.next(from: .like, direction: .right) == .dislike)
        #expect(TVOSPlayerControlPolicy.next(from: .dislike, direction: .right) == .comments)
        #expect(TVOSPlayerControlPolicy.next(from: .comments, direction: .right) == .save)
        #expect(TVOSPlayerControlPolicy.next(from: .save, direction: .right) == .more)
        #expect(TVOSPlayerControlPolicy.next(from: .more, direction: .right) == .more)
        #expect(TVOSPlayerControlPolicy.next(from: .prevVideo, direction: .left) == .prevVideo)
    }

    @Test("chrome visible: up from play/pause highlights the scrubber")
    func visibleChromeUpHighlightsScrubber() {
        #expect(TVOSPlayerControlPolicy.next(from: .playPause, direction: .up) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .seekBack, direction: .up) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .seekForward, direction: .up) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .like, direction: .up) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .more, direction: .up) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .scrubber, direction: .down) == .playPause)
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: .playPause, direction: .up)
                == .highlight(.scrubber))
    }

    @Test("chrome visible without highlight: first left/right starts from play/pause")
    func visibleChromeNilHighlightStartsOnPlayPause() {
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: nil, direction: .right)
                == .highlight(.seekForward))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: nil, direction: .left)
                == .highlight(.seekBack))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: nil, direction: .up)
                == .highlight(.scrubber))
        #expect(
            TVOSPlayerControlPolicy.outcome(
                chromeVisible: true, highlighted: nil, direction: .down)
                == .highlight(.playPause))
    }

    @Test("down from play/pause stays on the icon row")
    func downFromPlayPauseStaysOnIcons() {
        #expect(TVOSPlayerControlPolicy.next(from: .playPause, direction: .down) == .playPause)
        #expect(TVOSPlayerControlPolicy.next(from: .like, direction: .down) == .like)
    }

    @Test("up from scrubber reaches subscribe; info row walks channel ↔ subscribe")
    func infoRowAboveScrubber() {
        #expect(TVOSPlayerControlPolicy.next(from: .scrubber, direction: .up) == .subscribe)
        #expect(TVOSPlayerControlPolicy.next(from: .subscribe, direction: .down) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .channel, direction: .down) == .scrubber)
        #expect(TVOSPlayerControlPolicy.next(from: .channel, direction: .right) == .subscribe)
        #expect(TVOSPlayerControlPolicy.next(from: .subscribe, direction: .left) == .channel)
        #expect(TVOSPlayerControlPolicy.next(from: .channel, direction: .left) == .channel)
    }
}
