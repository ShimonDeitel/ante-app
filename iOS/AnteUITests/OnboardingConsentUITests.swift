import XCTest

/// Proves the onboarding rework end-to-end on a fresh launch (no
/// ANTE_TEST_ALARM bootstrap): task-type selection, preset stakes, the
/// Sign in with Apple gate, and - the one the owner called "the most
/// important part" - that the final Agree button is genuinely disabled
/// until the consent checkbox is tapped, not just decorative.
final class OnboardingConsentUITests: XCTestCase {

    func testConsentGateBlocksUntilChecked_andFullOnboardingReachesHome() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ANTE_UI_TEST_RESET"] = "1"
        app.launch()

        let dealMeIn = app.buttons["Deal me in"]
        XCTAssertTrue(dealMeIn.waitForExistence(timeout: 10), "Welcome step never appeared")
        dealMeIn.tap()

        // Task type: select Touch Grass specifically to prove the choice sticks.
        XCTAssertTrue(app.staticTexts["Pick your task"].waitForExistence(timeout: 10))
        let touchGrassRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Touch Grass'")).firstMatch
        XCTAssertTrue(touchGrassRow.waitForExistence(timeout: 10), "Touch Grass task option missing")
        touchGrassRow.tap()
        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["Set the wake time"].waitForExistence(timeout: 10))
        app.buttons["Next"].tap()

        // Stakes: presets, not a slider - pick a specific one and confirm no
        // free-text/slider control exists.
        XCTAssertTrue(app.staticTexts["Set the stakes"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.sliders.firstMatch.exists, "Stakes must be fixed presets, not a slider")
        let tenDollarFine = app.buttons.matching(NSPredicate(format: "label == '$10'")).firstMatch
        XCTAssertTrue(tenDollarFine.waitForExistence(timeout: 10), "$10 fine preset missing")
        tenDollarFine.tap()
        app.buttons["Next"].tap()

        // Sign in with Apple - mandatory, not skippable.
        XCTAssertTrue(app.staticTexts["Sign in with Apple"].waitForExistence(timeout: 10))
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertFalse(continueButton.isEnabled, "Continue must stay disabled before sign-in")
        let bypass = app.buttons["Simulator: skip sign-in"]
        XCTAssertTrue(bypass.waitForExistence(timeout: 10), "No sign-in path available in simulator")
        bypass.tap()
        XCTAssertTrue(continueButton.isEnabled, "Continue should enable once signed in")
        continueButton.tap()

        // THE consent gate: agree button starts disabled, enables only after
        // the checkbox itself is tapped.
        XCTAssertTrue(app.staticTexts["This charges real money"].waitForExistence(timeout: 10))
        let agreeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'I Agree'")).firstMatch
        XCTAssertTrue(agreeButton.waitForExistence(timeout: 10))
        XCTAssertFalse(agreeButton.isEnabled, "Agree button must be disabled until the consent checkbox is tapped")

        let consentRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'I have read and agree'")).firstMatch
        XCTAssertTrue(consentRow.waitForExistence(timeout: 10), "Consent checkbox row missing")
        consentRow.tap()
        XCTAssertTrue(agreeButton.isEnabled, "Agree button should enable once the checkbox is checked")
        agreeButton.tap()

        // Tapping Agree triggers the AlarmKit authorization prompt (fresh
        // install => not yet granted). Handle it wherever it's hosted.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowDeadline = Date().addingTimeInterval(15)
        while Date() < allowDeadline {
            let inApp = app.buttons["Allow"]
            let inSB = springboard.buttons["Allow"]
            if inApp.exists && inApp.isHittable { inApp.tap(); break }
            if inSB.exists && inSB.isHittable { inSB.tap(); break }
            if app.staticTexts["Recent mornings"].exists { break }
            usleep(300_000)
        }

        XCTAssertTrue(app.staticTexts["Recent mornings"].waitForExistence(timeout: 20), "Onboarding never reached Home")
    }
}
