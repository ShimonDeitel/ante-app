import XCTest

/// End-to-end proof of the enforcement chain that failed on-device:
/// ring -> user kills the alarm via the system Stop button -> the app
/// demands the fine on next open. Runs against the REAL AlarmKit alert on
/// the simulator's springboard, not a mock.
final class AlarmEnforcementUITests: XCTestCase {

    func testStoppingAlarmWithoutVerifyingDemandsTheFine() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ANTE_UI_TEST_RESET"] = "1"
        app.launchEnvironment["ANTE_TEST_ALARM"] = "40"
        app.launch()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // 1. AlarmKit authorization prompt. It may be hosted in-process or
        //    by springboard depending on OS version - probe both.
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
            let inApp = app.buttons["Allow"]
            let inSB = springboard.buttons["Allow"]
            if inApp.exists && inApp.isHittable { inApp.tap(); break }
            if inSB.exists && inSB.isHittable { inSB.tap(); break }
            usleep(500_000)
        }

        // Home shows ARMED once the test alarm is scheduled.
        XCTAssertTrue(
            app.staticTexts["ARMED"].waitForExistence(timeout: 20),
            "Test alarm was never scheduled - authorization or scheduling failed. App tree: \(app.debugDescription.prefix(1500))"
        )

        // 2. Background the app so the alarm alert fires on springboard,
        //    exactly like the owner's real-world test.
        XCUIDevice.shared.press(.home)

        // 3. Wait for the alarm to fire and kill it via the system Stop
        //    button without doing the bed check. Probe both processes.
        var stopped = false
        let ringDeadline = Date().addingTimeInterval(100)
        while Date() < ringDeadline {
            for candidate in [springboard.buttons["Stop"], app.buttons["Stop"]] {
                if candidate.exists && candidate.isHittable {
                    candidate.tap()
                    stopped = true
                    break
                }
            }
            if stopped { break }
            usleep(500_000)
        }
        XCTAssertTrue(
            stopped,
            "Alarm never fired / Stop button never appeared. Springboard tree: \(springboard.debugDescription.prefix(2000))"
        )

        // 4. Reopen the app: it MUST be blocked. Two legitimate shapes:
        //    - the alarm already left its alerting state -> straight to the
        //      pay-the-fine screen (deadline fallback), or
        //    - the alarm is still alerting -> the bed-check demand, whose
        //      only escapes are a passing photo, a snooze, or paying up.
        sleep(2)
        app.activate()

        let settleText = app.staticTexts["You stopped the alarm without checking in"]
        let verifyText = app.staticTexts["Make your bed, then show me"]
        let blockDeadline = Date().addingTimeInterval(20)
        var shape: String? = nil
        while Date() < blockDeadline {
            if settleText.exists { shape = "settle"; break }
            if verifyText.exists { shape = "verify"; break }
            usleep(500_000)
        }
        XCTAssertNotNil(
            shape,
            "ENFORCEMENT HOLE: stopped the alarm without verifying and the app demanded nothing. Tree: \(app.debugDescription.prefix(1500))"
        )

        // 5. Drive a money path to settlement. The "verify" shape's capture
        //    screen only grows a direct pay button AFTER a failed photo
        //    attempt - it has no immediate one. Its always-available money
        //    affordance is "Snooze instead", which also directly proves the
        //    owner's other explicit requirement: snoozing charges on the
        //    spot. Either shape ending in a real charge is valid proof the
        //    enforcement hole is closed.
        if shape == "verify" {
            let snoozeInstead = app.buttons["Snooze instead"]
            XCTAssertTrue(snoozeInstead.waitForExistence(timeout: 10), "No snooze escape on the verify screen")
            snoozeInstead.tap()

            let payAndSnooze = app.buttons.matching(NSPredicate(format: "label CONTAINS 'snooze'")).firstMatch
            XCTAssertTrue(payAndSnooze.waitForExistence(timeout: 10), "Snooze sheet never appeared")
            payAndSnooze.tap()

            // Charging + dismissing the sheet should clear the blocking
            // cover entirely (a fresh one-time alarm is re-armed for the
            // snooze window), landing back on Home.
            XCTAssertTrue(
                app.staticTexts["Recent mornings"].waitForExistence(timeout: 25),
                "Paying to snooze did not resolve back to Home"
            )
        } else {
            // The cover may still be animating in; a swallowed tap must not
            // fail the run - retap until the charge visibly starts.
            let pay = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay'")).firstMatch
            let settled = app.staticTexts["Settled"]
            sleep(1)
            for _ in 0..<4 {
                if settled.exists { break }
                if pay.exists && pay.isHittable { pay.tap() }
                if settled.waitForExistence(timeout: 6) { break }
            }
            XCTAssertTrue(settled.exists, "Fine payment did not settle")
        }
    }
}
