//
//  ProfileTests.swift
//  GameBacklogUITests
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import XCTest

final class ProfileTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testFillingProfile() {
        app.tabBars.buttons["Profile"].tap()
        app.textFields["firstName"].tap()
        app.textFields["firstName"].typeText("Serhii")
        app.textFields["lastName"].tap()
        app.textFields["lastName"].typeText("Pershuta")
        app.textFields["nickname"].tap()
        app.textFields["nickname"].typeText("Hunter_Lies")
        app.textFields["email"].tap()
        app.textFields["email"].typeText("hunter8569@gmail.com")
        app.navigationBars.buttons["Save"].tap()
        app.tabBars.buttons["Settings"].tap()
        app.tabBars.buttons["Profile"].tap()

        XCTAssertEqual(app.textFields["firstName"].value as? String, "Serhii")
        XCTAssertEqual(app.textFields["lastName"].value as? String, "Pershuta")
        XCTAssertEqual(app.textFields["nickname"].value as? String, "Hunter_Lies")
        XCTAssertEqual(app.textFields["email"].value as? String, "hunter8569@gmail.com")
    }
}
