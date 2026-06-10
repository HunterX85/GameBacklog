//
//  GameBacklogUITests.swift
//  GameBacklogUITests
//
//  Created by Serhii Pershuta on 10.06.2026.
//

import XCTest

final class GameBacklogUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - List

    @MainActor
    func testInitialGamesAreVisible() {
        XCTAssertTrue(app.staticTexts["Witcher 3"].exists)
        XCTAssertTrue(app.staticTexts["GTA 6"].exists)
    }

    // MARK: - Add Game

    @MainActor
    func testAddGameOpensSheet() {
        app.navigationBars["Game Backlog"].buttons["Add"].tap()
        XCTAssertTrue(app.navigationBars["Нова гра"].exists)
    }

    @MainActor
    func testAddGameAppearsInList() {
        openAddGameSheet()

        app.textFields["Назва гри"].tap()
        app.textFields["Назва гри"].typeText("Cyberpunk 2077")

        app.textFields["Платформа (PC, PS5...)"].tap()
        app.textFields["Платформа (PC, PS5...)"].typeText("PC")

        app.navigationBars["Нова гра"].buttons["Додати"].tap()

        XCTAssertTrue(app.staticTexts["Cyberpunk 2077"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["PC"].exists)
    }

    @MainActor
    func testAddGameWithStatusPicker() {
        openAddGameSheet()

        app.textFields["Назва гри"].tap()
        app.textFields["Назва гри"].typeText("Dark Souls")

        app.textFields["Платформа (PC, PS5...)"].tap()
        app.textFields["Платформа (PC, PS5...)"].typeText("PS5")

        // .pickerStyle(.menu) рендерить кнопку з поточним значенням
        app.buttons["Хочу пройти"].tap()
        app.buttons["В прогресі"].tap()

        app.navigationBars["Нова гра"].buttons["Додати"].tap()

        XCTAssertTrue(app.staticTexts["Dark Souls"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["В прогресі"].exists)
    }

    @MainActor
    func testCancelAddGameDoesNotAddToList() {
        let countBefore = app.cells.count

        openAddGameSheet()

        app.textFields["Назва гри"].tap()
        app.textFields["Назва гри"].typeText("Ghost Game")

        app.navigationBars["Нова гра"].buttons["Відміна"].tap()

        XCTAssertFalse(app.staticTexts["Ghost Game"].exists)
        XCTAssertEqual(app.cells.count, countBefore)
    }

    // MARK: - Delete Game

    @MainActor
    func testDeleteGameRemovesItFromList() {
        let cell = app.cells.containing(.staticText, identifier: "Witcher 3").firstMatch
        cell.swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["Witcher 3"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeleteAllGamesResultsInEmptyList() {
        deleteAllGames()
        XCTAssertEqual(app.cells.count, 0)
    }

    // MARK: - Helpers

    private func openAddGameSheet() {
        app.navigationBars["Game Backlog"].buttons["Add"].tap()
        _ = app.navigationBars["Нова гра"].waitForExistence(timeout: 2)
    }

    private func deleteAllGames() {
        while app.cells.count > 0 {
            app.cells.firstMatch.swipeLeft()
            app.buttons["Delete"].tap()
        }
    }
}
