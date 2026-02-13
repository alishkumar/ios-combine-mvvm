import XCTest

final class NewsUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testNewsTabDisplay() throws {
        let newsTab = app.tabBars.buttons["News"]
        XCTAssertTrue(newsTab.exists)
        newsTab.tap()
        
        let tableView = app.tables.firstMatch
        XCTAssertTrue(tableView.waitForExistence(timeout: 5.0))
    }
    
    func testBookmarksTabDisplay() throws {
        let bookmarksTab = app.tabBars.buttons["Bookmarks"]
        XCTAssertTrue(bookmarksTab.exists)
        bookmarksTab.tap()
        
        let tableView = app.tables.firstMatch
        XCTAssertTrue(tableView.waitForExistence(timeout: 2.0))
    }
    
    func testArticleDetailNavigation() throws {
        let newsTab = app.tabBars.buttons["News"]
        newsTab.tap()
        
        let tableView = app.tables.firstMatch
        XCTAssertTrue(tableView.waitForExistence(timeout: 5.0))
        
        if tableView.cells.count > 0 {
            let firstCell = tableView.cells.element(boundBy: 0)
            firstCell.tap()
            
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(backButton.waitForExistence(timeout: 2.0))
        }
    }
    
    func testSearchFunctionality() throws {
        let newsTab = app.tabBars.buttons["News"]
        newsTab.tap()
        
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 2.0) {
            searchField.tap()
            searchField.typeText("technology")
            app.keyboards.buttons["Search"].tap()
            
            let tableView = app.tables.firstMatch
            XCTAssertTrue(tableView.waitForExistence(timeout: 5.0))
        }
    }
    
    func testPullToRefresh() throws {
        let newsTab = app.tabBars.buttons["News"]
        newsTab.tap()
        
        let tableView = app.tables.firstMatch
        XCTAssertTrue(tableView.waitForExistence(timeout: 5.0))
        
        let start = tableView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let end = tableView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
