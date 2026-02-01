//
//  ParachuteUITestsLaunchTests.swift
//  ParachuteUITests
//
//  Created by Ben Gresham on 01/02/2026.
//

import XCTest

/// Launch-snapshot UI tests for the app.
final class ParachuteUITestsLaunchTests: XCTestCase {

    /// Ensures launch tests run for each UI configuration.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    /// Configures the UI test environment for launch tests.
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app and captures a launch screenshot.
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
