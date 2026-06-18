//
//  QuitERGYUITests.swift
//  QuitERGYUITests
//
//  Created by Georgios Avenidis on 30.10.25.
//

import XCTest

final class QuitERGYUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SKIP_ONBOARDING"] = "1"
        app.launchEnvironment["SHOW_ONBOARDING_LAYOUT_DEBUG"] = "0"
        app.launchEnvironment["UITEST_SHOW_PAYWALL_ON_LAUNCH"] = "1"
        app.launchEnvironment["UITEST_BYPASS_PURCHASES"] = "1"

        addUIInterruptionMonitor(withDescription: "StoreKit purchase confirmation") { alert in
            let prioritizedButtons = [
                "Subscribe", "Buy", "Continue", "Confirm", "OK",
                "Abonnieren", "Kaufen", "Fortfahren", "Bestätigen"
            ]

            for title in prioritizedButtons {
                let button = alert.buttons[title]
                if button.exists {
                    button.tap()
                    return true
                }
            }

            let fallback = alert.buttons.firstMatch
            if fallback.exists {
                fallback.tap()
                return true
            }
            return false
        }

        app.launch()

        let paywallTitle = app.staticTexts["QuitERGY Premium"]
        XCTAssertTrue(paywallTitle.waitForExistence(timeout: 10), "Paywall should be visible.")

        let startTrialButton = app.buttons["Start free trial"]
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(
            startTrialButton.waitForExistence(timeout: 12) || continueButton.waitForExistence(timeout: 12),
            "Purchase CTA should be visible."
        )

        if startTrialButton.exists {
            startTrialButton.tap()
        } else {
            continueButton.tap()
        }

        // Triggers interruption handler for system purchase prompts.
        app.tap()

        // Rating prompt can appear after successful purchase; dismiss to continue assertions.
        let maybeLater = app.buttons["Maybe later"]
        if maybeLater.waitForExistence(timeout: 5) {
            maybeLater.tap()
        }

        let paywallGone = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: paywallTitle
        )
        wait(for: [paywallGone], timeout: 20)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testAppStoreIPadScreenshots() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SHOW_ONBOARDING_LAYOUT_DEBUG"] = "0"
        app.launch()

        sleep(2)
        capture(app: app, name: "01-Onboarding-Step1")

        advanceIfNeeded(app)
        sleep(1)
        capture(app: app, name: "02-Onboarding-Step2")

        advanceIfNeeded(app)
        sleep(1)
        capture(app: app, name: "03-Onboarding-Step3")
    }

    @MainActor
    private func capture(app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func advanceIfNeeded(_ app: XCUIApplication) {
        let options = ["1 per week", "2-3 per week", "1 per day", "2 or more per day"]
        for option in options where app.staticTexts[option].exists {
            app.staticTexts[option].tap()
            break
        }

        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 2), continueButton.isEnabled {
            continueButton.tap()
        }
    }

}
