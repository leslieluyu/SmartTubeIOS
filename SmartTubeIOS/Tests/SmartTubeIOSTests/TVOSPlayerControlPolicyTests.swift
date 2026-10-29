import Foundation
import Testing

@testable import SmartTubeIOS

@Suite("tvOS YouTube-like player chrome navigation")
struct TVOSPlayerControlPolicyTests {

    @Test("left/right on play/pause seek instead of moving the highlight")
    func transportLeftRightSeek() {
        #expect(
            TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                control: .playPause, direction: .left))
        #expect(
            TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                control: .playPause, direction: .right))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                control: .prevVideo, direction: .left))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                control: .playPause, direction: .up))
        #expect(
            !TVOSPlayerControlPolicy.seeksInsteadOfMovingHighlight(
                control: .like, direction: .left))
    }

    @Test("down from play/pause lands on like; up from like returns to play/pause")
    func verticalTransportToActions() {
        #expect(TVOSPlayerControlPolicy.next(from: .playPause, direction: .down) == .like)
        #expect(TVOSPlayerControlPolicy.next(from: .like, direction: .up) == .playPause)
        #expect(TVOSPlayerControlPolicy.next(from: .more, direction: .up) == .playPause)
    }

    @Test("up from play/pause lands on subscribe")
    func upFromTransportGoesToSubscribe() {
        #expect(TVOSPlayerControlPolicy.next(from: .playPause, direction: .up) == .subscribe)
        #expect(TVOSPlayerControlPolicy.next(from: .subscribe, direction: .down) == .playPause)
        #expect(TVOSPlayerControlPolicy.next(from: .channel, direction: .down) == .playPause)
    }

    @Test("action row walks like → dislike → comments → save → options")
    func actionRowOrder() {
        #expect(TVOSPlayerControlPolicy.next(from: .like, direction: .right) == .dislike)
        #expect(TVOSPlayerControlPolicy.next(from: .dislike, direction: .right) == .comments)
        #expect(TVOSPlayerControlPolicy.next(from: .comments, direction: .right) == .save)
        #expect(TVOSPlayerControlPolicy.next(from: .save, direction: .right) == .more)
        #expect(TVOSPlayerControlPolicy.next(from: .more, direction: .right) == .more)
        #expect(TVOSPlayerControlPolicy.next(from: .more, direction: .left) == .save)
        #expect(TVOSPlayerControlPolicy.next(from: .like, direction: .left) == .like)
    }

    @Test("info row walks channel ↔ subscribe")
    func infoRowOrder() {
        #expect(TVOSPlayerControlPolicy.next(from: .channel, direction: .right) == .subscribe)
        #expect(TVOSPlayerControlPolicy.next(from: .subscribe, direction: .left) == .channel)
        #expect(TVOSPlayerControlPolicy.next(from: .channel, direction: .left) == .channel)
    }
}
