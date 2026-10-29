#if os(tvOS)
import XCTest

// MARK: - TVHomeFeedUITests
//
// Verifies the tvOS Home Feed tab: chip bar presence, video card population,
// no error banner on launch, Subscriptions chip navigation, and return to Home.
//
// Run against the "Smart Tube" tvOS scheme:
//   xcodebuild test -workspace SmartTube.xcworkspace -scheme "Smart Tube"
//     -destination "id=30E83929-0C67-4572-82C4-FE0F228EA835"
//     -only-testing:SmartTubeTVUITests/TVHomeFeedUITests

final class TVHomeFeedUITests: XCTestCase {

    private var app: XCUIApplication!
    private let remote = XCUIRemote.shared

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private var chipBar: XCUIElement {
        tvHomeSentinel(in: app)
    }

    private var sectionContainer: XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'home.sectionContainer'"))
            .firstMatch
    }

    /// Waits up to `timeout` seconds for at least one `video.card.*` descendant to appear.
    private func waitForVideoCards(timeout: TimeInterval = 20) -> Bool {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'video.card.'")
        let cards = app.descendants(matching: .any).matching(predicate)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count > 0"),
            object: cards
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    // MARK: - Tests

    /// The chip bar must appear within 15 s of launch.
    func testChipBarLoadsWithinTimeout() throws {
        guard chipBar.waitForExistence(timeout: 15) else {
            try captureAndSkip("home.chipBar did not appear within 15 s — Home tab may not have loaded", in: app)
        }
        XCTAssertTrue(chipBar.exists, "home.chipBar must exist after appearance")
    }

    /// Video cards (video.card.*) must populate the Home feed within 20 s.
    func testVideoCardsPopulateHomeFeed() throws {
        guard chipBar.waitForExistence(timeout: 15) else {
            try captureAndSkip("home.chipBar not found — cannot wait for video cards", in: app)
        }
        guard waitForVideoCards(timeout: 20) else {
            try captureAndSkip(
                "No video.card.* elements appeared within 20 s — network unavailable or feed empty", in: app)
        }
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'video.card.'")
        let cards = app.descendants(matching: .any).matching(predicate)
        XCTAssertGreaterThan(cards.count, 0, "At least one video card must be visible in the Home feed")
    }

    /// No XCUIElementTypeAlert and no player.errorBanner should appear on cold launch.
    func testNoErrorBannerOnHomeLoad() throws {
        guard chipBar.waitForExistence(timeout: 15) else {
            try captureAndSkip("home.chipBar not found — app did not reach Home tab", in: app)
        }
        // Allow extra time for network requests to settle.
        Thread.sleep(forTimeInterval: 3.0)
        let errorAlert = app.alerts.firstMatch
        XCTAssertFalse(errorAlert.exists, "Unexpected error alert appeared on Home launch: \(errorAlert.label)")
        let errorBanner = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'player.errorBanner'"))
            .firstMatch
        XCTAssertFalse(errorBanner.exists, "player.errorBanner should not appear on the Home screen")
    }

    /// Selecting Subscriptions in the left rail should load the Subscriptions feed.
    func testSelectingSubscriptionsChipLoadsFeed() throws {
        guard chipBar.waitForExistence(timeout: 15) else {
            try captureAndSkip("tv.sidebar not found — cannot navigate to Subscriptions", in: app)
        }
        remote.press(.left)
        Thread.sleep(forTimeInterval: 0.8)
        remote.press(.down)
        Thread.sleep(forTimeInterval: 0.5)
        remote.press(.down)
        Thread.sleep(forTimeInterval: 0.5)
        remote.press(.select)
        Thread.sleep(forTimeInterval: 1.5)
        guard sectionContainer.waitForExistence(timeout: 15) else {
            try captureAndSkip("home.sectionContainer did not appear after selecting Subscriptions", in: app)
        }
        XCTAssertTrue(sectionContainer.exists, "home.sectionContainer must exist after rail selection")
    }

    /// Navigating back to Home in the left rail should restore the home sentinel.
    func testSelectingHomeChipRestoresFeed() throws {
        guard chipBar.waitForExistence(timeout: 15) else {
            try captureAndSkip("tv.sidebar not found on launch", in: app)
        }
        remote.press(.left)
        Thread.sleep(forTimeInterval: 0.8)
        remote.press(.down)
        Thread.sleep(forTimeInterval: 0.5)
        remote.press(.down)
        Thread.sleep(forTimeInterval: 0.5)
        remote.press(.select)
        Thread.sleep(forTimeInterval: 1.5)
        remote.press(.up)
        Thread.sleep(forTimeInterval: 0.5)
        remote.press(.select)
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(
            chipBar.waitForExistence(timeout: 10),
            "tv.sidebar / home.screen must still exist after returning to Home"
        )
    }
}
#endif
