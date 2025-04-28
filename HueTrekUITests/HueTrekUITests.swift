//
//  HueTrekUITests.swift
//  HueTrekUITests
//
//  Created by Louis Roehrs on 3/10/25.
//

import XCTest

final class HueTrekUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testBasicUIElements() throws {
        // Test that main navigation elements exist
        XCTAssertTrue(app.buttons["Lights"].exists)
        XCTAssertTrue(app.buttons["Groups"].exists)
        XCTAssertTrue(app.buttons["Sensors"].exists)
    }
    
    func testKeyValueIndicatorDisplay() throws {
        // Assuming there's a KeyValueIndicator visible on the main screen
        let keyValueView = app.otherElements["KeyValueIndicator"]
        XCTAssertTrue(keyValueView.exists)
        
        // Test text elements within the indicator
        XCTAssertTrue(keyValueView.staticTexts.element.exists)
    }
    
    func testBridgeSelectorNavigation() throws {
        // Test bridge selector button exists and can be tapped
        let bridgeSelectorButton = app.buttons["BridgeSelector"]
        XCTAssertTrue(bridgeSelectorButton.exists)
        bridgeSelectorButton.tap()
        
        // Verify bridge selector view appears
        let bridgeSelectorView = app.otherElements["BridgeSelectorView"]
        XCTAssertTrue(bridgeSelectorView.exists)
    }
    
    func testGroupsViewInteraction() throws {
        // Navigate to Groups tab
        app.buttons["Groups"].tap()
        
        // Verify Groups view is displayed
        let groupsView = app.otherElements["GroupsView"]
        XCTAssertTrue(groupsView.exists)
        
        // Test group list exists
        let groupsList = app.scrollViews["GroupsList"]
        XCTAssertTrue(groupsList.exists)
    }
    
    func testLightsViewInteraction() throws {
        // Navigate to Lights tab
        app.buttons["Lights"].tap()
        
        // Verify Lights view is displayed
        let lightsView = app.otherElements["LightsView"]
        XCTAssertTrue(lightsView.exists)
        
        // Test lights list exists
        let lightsList = app.scrollViews["LightsList"]
        XCTAssertTrue(lightsList.exists)
    }
    
    func testNoBridgeFoundView() throws {
        // Force no bridge state (you'll need to implement a way to do this)
        // This could be done through launch arguments or UI interaction
        
        // Verify NoBridgeFoundView appears
        let noBridgeView = app.otherElements["NoBridgeFoundView"]
        XCTAssertTrue(noBridgeView.exists)
        
        // Test discover button exists and can be tapped
        let discoverButton = noBridgeView.buttons["DiscoverBridge"]
        XCTAssertTrue(discoverButton.exists)
        discoverButton.tap()
    }
}
