//
//  HueTrekTests.swift
//  HueTrekTests
//
//  Created by Louis Roehrs on 3/10/25.
//

import Testing
import SwiftUI
@testable import HueTrek

struct HueTrekTests {
    
    // MARK: - HueManager Tests
    
    @Test func testHueManagerInitialization() async throws {
        let manager = HueManager()
        #expect(manager.currentTab == .lights)
        #expect(manager.bridgeConfigurations.isEmpty)
    }
    
    @Test func testBridgeConfiguration() async throws {
        let config = BridgeConfiguration(name: "Test Bridge", bridgeIP: "192.168.1.100", apiKey: "testkey123")
        #expect(config.name == "Test Bridge")
        #expect(config.bridgeIP == "192.168.1.100")
        #expect(config.apiKey == "testkey123")
    }
    
    @Test func testUIConfig() async throws {
        let ui = UIConfig(
            footerHeight: 36,
            headerHeight: 40,
            headerFontSize: 55,
            footerButtonFontSize: 28,
            footerLabelFontSize: 48,
            rowFontSize: 30,
            rowHeight: 40,
            itemHeight: 24,
            itemFontSize: 32
        )
        #expect(ui.footerHeight == 36)
        #expect(ui.headerHeight == 40)
        #expect(ui.headerFontSize == 55)
    }
    
    @Test func testKeyValueIndicator() async throws {
        let key = "TEST"
        let value = "123"
        let indicator = KeyValueIndicator(key: key, value: value)
        
        let view = indicator.body
        // Test that view exists and has correct modifiers
        #expect(Mirror(reflecting: view).children.count > 0)
    }
    
    @Test func testPreviewHueManager() async throws {
        let previewManager = HueManager.preview
        #expect(!previewManager.bridgeConfigurations.isEmpty)
        #expect(previewManager.currentBridgeConfig != nil)
        #expect(previewManager.bridgeConfigurations.count == 4)
    }
    
    @Test func testGroupStructure() async throws {
        let groupState = LightGroup.GroupState(all_on: true, any_on: true)
        let groupAction = LightGroup.GroupAction(
            on: true,
            bri: 254,
            hue: 0,
            sat: 0,
            effect: nil,
            xy: nil,
            ct: nil,
            alert: nil,
            colormode: nil
        )
        
        let group = LightGroup(
            id: "1",
            name: "Living Room",
            lights: ["1", "2", "3"],
            type: "Room",
            state: groupState,
            action: groupAction,
            class: "Living room"
        )
        
        #expect(group.id == "1")
        #expect(group.name == "Living Room")
        #expect(group.lights.count == 3)
        #expect(group.state.all_on)
        #expect(group.action.bri == 254)
    }
}
