//
//  HueManager.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import Foundation
import Network
import SwiftUI
import AVFoundation // Import AVFoundation for audio playback

enum ViewTab {
    case lights
    case sensors
    case groups
}


struct BridgeConfiguration: Codable, Identifiable {
    let id: UUID
    var name: String
    var bridgeIP: String
    var apiKey: String
    
    init(name: String, bridgeIP: String, apiKey: String) {
        self.id = UUID()
        self.name = name
        self.bridgeIP = bridgeIP
        self.apiKey = apiKey
    }
}

struct UIConfig: Codable {
    var footerHeight: CGFloat
    var headerHeight: CGFloat
    var headerFontSize: CGFloat
    var footerButtonFontSize: CGFloat
    var footerLabelFontSize: CGFloat
    var rowFontSize: CGFloat
    var rowHeight: CGFloat
    
    init(footerHeight: CGFloat,
         headerHeight: CGFloat,
         headerFontSize: CGFloat,
         footerButtonFontSize: CGFloat,
         footerLabelFontSize: CGFloat,
         rowFontSize: CGFloat,
         rowHeight: CGFloat
    ) {
        self.footerHeight = footerHeight
        self.headerHeight = headerHeight
        self.headerFontSize = headerFontSize
        self.footerButtonFontSize = footerButtonFontSize
        self.footerLabelFontSize = footerLabelFontSize
        self.rowFontSize = rowFontSize
        self.rowHeight = rowHeight
    }
}
    
class HueManager: ObservableObject {
    @Published var bridgeConfigurations: [BridgeConfiguration] {
        didSet {
            if let encoded = try? JSONEncoder().encode(bridgeConfigurations) {
                UserDefaults.standard.set(encoded, forKey: "bridgeConfigurations")
            }
        }
    }
    
    @Published var currentBridgeConfig: BridgeConfiguration? {
        didSet {
            if let config = currentBridgeConfig {
                UserDefaults.standard.set(config.id.uuidString, forKey: "currentBridgeId")
                bridgeIP = config.bridgeIP
                apiKey = config.apiKey
                fetchLights()
                fetchGroups()
            } else {
                bridgeIP = nil
                apiKey = nil
                lights = []
            }
        }
    }
    
    @Published var bridgeIP: String?
    @Published var apiKey: String?
    @Published var lights: [Light] = []
    @Published var isDiscovering = false
    @Published var noDiscoveryAttempts = true
    @Published var error: String?
    @Published var isAddingNewBridge = false
    @Published var newBridgeAdded = false
    @Published var showingBridgeSelector = false
    @Published var currentTab: ViewTab = .lights
    
    @Published var sensors: [Sensor] = []
    
    @Published var ui:UIConfig = UIConfig(
        footerHeight:36,
        headerHeight:40,
        headerFontSize: 55,
        footerButtonFontSize: 28,
        footerLabelFontSize: 48,
        rowFontSize: 30,
        rowHeight: 40
    )
    
    struct Group: Identifiable, Codable {
        let id: String
        var name: String
        var lights: [String]
        var type: String
        var state: GroupState
        var action: GroupAction
        var `class`: String
        
        struct GroupState: Codable {
            var all_on: Bool
            var any_on: Bool
        }
        
        struct GroupAction: Codable {
            var on: Bool
            var bri: Int
            var hue: Int
            var sat: Int
            var effect: String?
            var xy: [Double]?
            var ct: Int?
            var alert: String?
            var colormode: String?
        }
    }
    
    @Published var groups: [Group] = []
    
    private var audioPlayer: AVAudioPlayer?
    
    struct Light: Identifiable, Codable {
        let id: String
        var name: String
        var state: State
        var isColorPickerVisible: Bool = false
        var selectedColor: Color?
        
        private enum CodingKeys: String, CodingKey {
            case id, name, state
        }
        
        struct State: Codable {
            var on: Bool?
            var bri: Int?
            var hue: Int?
            var sat: Int?
            var reachable: Bool
        }
        
    }
    
    struct Sensor: Identifiable, Codable {
        let id: String
        var name: String
        var type: String
        var manufacturername: String
        var productname: String
        var state: SensorState
        var config: SensorConfig
        
        struct SensorState: Codable {
            var rotaryevent: Int?
            var expectedrotation: Int?
            var expectedeventduration: Int?
            var lastupdated: String?
        }
        
        struct SensorConfig: Codable {
            var on: Bool
            var battery: Int
            var reachable: Bool
        }
    }
    
    // MARK: - Error Handling
    private enum HueError {
        case network(Error)
        case noData
        case decodingError(Error)
        case bridgeError(String)
        
        var userMessage: String {
            switch self {
            case .network(_):
                return "Unable to connect to bridge"
            case .noData:
                return "No data received"
            case .decodingError(_):
                return "Unable to process bridge response"
            case .bridgeError(let message):
                return message
            }
        }
    }
    
    private func handleError(_ error: HueError, showInUI: Bool = true) {
        // Only set the error property if we want to show it in the UI
        if showInUI {
            DispatchQueue.main.async {
                self.error = error.userMessage
            }
        }
        // Network errors are silently handled unless explicitly requested to show in UI
        #if DEBUG
        switch error {
        case .network(let err):
            print("DEBUG: Network error occurred: \(err.localizedDescription)")
        case .decodingError(let err):
            print("DEBUG: Decoding error occurred: \(err.localizedDescription)")
        default:
            break
        }
        #endif
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "bridgeConfigurations"),
           let decoded = try? JSONDecoder().decode([BridgeConfiguration].self, from: data) {
            self.bridgeConfigurations = decoded
        } else {
            self.bridgeConfigurations = []
        }
        
        if let currentBridgeId = UserDefaults.standard.string(forKey: "currentBridgeId"),
           let uuid = UUID(uuidString: currentBridgeId),
           let config = bridgeConfigurations.first(where: { $0.id == uuid }) {
            self.currentBridgeConfig = config
        } else {
            self.currentBridgeConfig = nil
        }
    }
    
    func fetchCurrentTab() {
        switch self.currentTab {
        case .lights:
            self.fetchLights()
        case .groups:
            self.fetchGroups()
        case .sensors:
            self.fetchSensors()
        }
    }
    
    func addBridgeTapped() {
        self.discoverBridge()
        self.playSound(sound: "colorpickerslidedown")
        self.isAddingNewBridge = true
    }
    
    func addNewBridgeConfiguration(name: String) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        let newConfig = BridgeConfiguration(name: name, bridgeIP: bridgeIP, apiKey: apiKey)
        bridgeConfigurations.append(newConfig)
        currentBridgeConfig = newConfig
    }
    
    func updateBridgeName(_ newName: String) {
        guard var currentConfig = currentBridgeConfig else { return }
        if let index = bridgeConfigurations.firstIndex(where: { $0.id == currentConfig.id }) {
            currentConfig.name = newName
            bridgeConfigurations[index] = currentConfig
            currentBridgeConfig = currentConfig
        }
    }
    
    func switchToBridge(withId id: UUID) {
        if let config = bridgeConfigurations.first(where: { $0.id == id }) {
            currentBridgeConfig = config

        }
        fetchLights()
        fetchGroups()
        fetchSensors()
    }
    
    func removeBridge(withId id: UUID) {
        bridgeConfigurations.removeAll(where: { $0.id == id })
        if currentBridgeConfig?.id == id {
            currentBridgeConfig = bridgeConfigurations.first
        }
        if bridgeConfigurations.isEmpty {
            currentBridgeConfig = nil
        }
    }
    
    func discoverBridge() {
        playSound(sound: "tos_bridgescanner")
        isDiscovering = true
        isAddingNewBridge = true
        noDiscoveryAttempts = false
        error = nil
        
        // First try meethue.com discovery
        let url = URL(string: "https://discovery.meethue.com")!
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let bridges = try? JSONDecoder().decode([BridgeDiscovery].self, from: data),
                   let bridge = bridges.first {
                    self?.bridgeIP = bridge.internalipaddress
                    self?.isDiscovering = false
                    self?.stopSound()
                } else {
                    print("db: fallback")
                    // Fall back to UPnP discovery
                    self?.discoverBridgeUPnP()
                }
            }
        }.resume()
    }
    
    private func discoverBridgeUPnP() {
        let ssdpAddress = "239.255.255.250"
        let ssdpPort: UInt16 = 1900
        
        print("UPnP")
        guard let udpSocket = try? NWConnection(
            to: NWEndpoint.hostPort(host: .init(ssdpAddress), port: .init(integerLiteral: ssdpPort)),
            using: .udp
        )
        else {
            isDiscovering = false
            print("Failed to create UDP socket")
            return
        }
        
        let searchMessage = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1900\r
        MAN: "ssdp:discover"\r
        MX: 2\r
        ST: ssdp:all\r
        \r\n
        """
        
        udpSocket.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                udpSocket.send(content: searchMessage.data(using: .utf8), completion: .contentProcessed { _ in })
                print("ready")
            case .failed(let error):
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                    self?.isDiscovering = false
                    self?.stopSound()
                }
            default:
                print("default")
                break
            }
        }
        
        udpSocket.receiveMessage { [weak self] data, _, _, error in
            if let data = data,
               let response = String(data: data, encoding: .utf8),
               response.contains("IpBridge") {
                let lines = response.components(separatedBy: "\r\n")
                if let locationLine = lines.first(where: { $0.starts(with: "LOCATION:") }),
                   let urlString = locationLine.components(separatedBy: " ").last,
                   let url = URL(string: urlString),
                   let bridgeIP = url.host {
                    DispatchQueue.main.async {
                        print("async")
                        self?.bridgeIP = bridgeIP
                        self?.isDiscovering = false
                        self?.stopSound()
                    }
                }
            }
        }
        
        udpSocket.start(queue: .global())
    }
    
    func pairWithBridge(completion: (() -> Void)? = nil) {
        guard let bridgeIP = bridgeIP else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(["devicetype": "hue_ios_app"])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let response = try? JSONDecoder().decode([BridgeResponse].self, from: data),
                   let success = response.first?.success {
                    self?.apiKey = success.username
                    // Add new bridge configuration with default name
                    self?.addNewBridgeConfiguration(name: "Bridge \(self?.bridgeConfigurations.count ?? 0 + 1)")
                    self?.fetchLights()
                    self?.fetchGroups()
                    self?.fetchSensors()
                    completion?()
                } else if let error = error {
                    self?.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func hueLightToSwiftColor(light: Light) -> Color {
        return Color(
            hue: Double(light.state.hue!) / 65536.0,
            saturation: Double(light.state.sat!) / 255.0,
            brightness: Double(light.state.bri!) / 254.0)
    }
    
    func updateColor(light: Light, color: Color) {
        // Convert the Color to HSB values
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        
        // Convert RGB to HSB
        let (hue, saturation, brightness) = rgbToHsb(red: red, green: green, blue: blue)
        
        // Update the light's state
        if let index = lights.firstIndex(where: { $0.id == light.id }) {
            lights[index].selectedColor = color
            lights[index].state.hue = Int(hue * 65535) // Convert to Hue scale
            lights[index].state.sat = Int(saturation * 255) // Convert to Saturation scale
            lights[index].state.bri = Int(brightness * 254) // Convert to Brightness scale
        }
        
        // Send the update to the Hue bridge
        sendColorUpdateToBridge(light: light, hue: Int(hue * 65535), saturation: Int(saturation * 255), brightness: Int(brightness * 254))
    }
    
    private func sendColorUpdateToBridge(light: Light, hue: Int, saturation: Int, brightness: Int) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/lights/\(light.id)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let body: [String: Any] = [
            "on": light.state.on as Any,
            "hue": hue,
            "sat": saturation,
            "bri": brightness
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    print("Error updating light color: \(error.localizedDescription)")
                } else {
                    print("Successfully updated light color for \(light.name)")
                }
            }
        }.resume()
    }
    
    // Helper function to convert RGB to HSB
    private func rgbToHsb(red: CGFloat, green: CGFloat, blue: CGFloat) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let maxColor = max(red, green, blue)
        let minColor = min(red, green, blue)
        let delta = maxColor - minColor
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        let brightness = maxColor
        
        if maxColor != 0 {
            saturation = delta / maxColor
        }
        
        if delta != 0 {
            if maxColor == red {
                hue = (green - blue) / delta
            } else if maxColor == green {
                hue = 2 + (blue - red) / delta
            } else {
                hue = 4 + (red - green) / delta
            }
            hue *= 60
            if hue < 0 {
                hue += 360
            }
        }
        
        return (hue / 360, saturation, brightness)
    }
    
    func fetchLights() {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/lights")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                self?.handleError(.network(error), showInUI: false)
                return
            }
            
            guard let data = data else {
                self?.handleError(.noData, showInUI: false)
                return
            }
            
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    let lightsData = try JSONDecoder().decode([String: LightResponse].self, from: data)
                    DispatchQueue.main.async {
                        self?.lights = lightsData.map { id, response in
                            Light(id: id, name: response.name, state: response.state)
                        }
                        self?.lights.sort { $0.name < $1.name }
                    }
                }
            } catch {
                self?.handleError(.decodingError(error), showInUI: false)
            }
        }.resume()
    }
    
    func playSound(sound: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play() // Play the sound
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
    
    func toggleColorPicker(_ light: Light) {
        if let index = lights.firstIndex(where: { $0.id == light.id }) {
            lights[index].isColorPickerVisible.toggle()
        }
    }
    func toggleLight(_ light: Light) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        print("Toggle light \(light.name)")  // Play sound
        if light.state.on! {
            playSound(sound: "lightOff")
        } else {
            playSound(sound: "lightOn")
        }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/lights/\(light.id)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONEncoder().encode(["on": !light.state.on!])
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchLights()
            }
        }.resume()
    }
    
    func setBrightness(_ brightness: Int, for light: Light) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/lights/\(light.id)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONEncoder().encode(["bri": brightness])
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchLights()
            }
        }.resume()
    }
    
    func fetchSensors() {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/sensors")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                self?.handleError(.network(error), showInUI: false)
                return
            }
            
            guard let data = data else {
                self?.handleError(.noData, showInUI: false)
                return
            }
            
            do {
                if let sensorsData = try JSONDecoder().decode([String: Sensor].self, from: data) {
                    DispatchQueue.main.async {
                        self?.sensors = sensorsData.map { id, sensor in
                            var sensor = sensor
                            sensor.id = id
                            return sensor
                        }
                        self?.sensors.sort { $0.name < $1.name }
                    }
                }
            } catch {
                self?.handleError(.decodingError(error), showInUI: false)
            }
        }.resume()
    }
    
    func fetchGroups() {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/groups")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                self?.handleError(.network(error), showInUI: false)
                return
            }
            
            guard let data = data else {
                self?.handleError(.noData, showInUI: false)
                return
            }
            
            do {
                let groupsData = try JSONDecoder().decode([String: Group].self, from: data)
                DispatchQueue.main.async {
                    self?.groups = groupsData.map { id, group in
                        Group(id: id,
                              name: group.name,
                              lights: group.lights,
                              type: group.type,
                              state: group.state,
                              action: group.action,
                              class: group.class)
                    }
                    self?.groups.sort { $0.name < $1.name }
                }
            } catch {
                self?.handleError(.decodingError(error), showInUI: false)
            }
        }.resume()
    }
    
    func toggleGroup(_ group: Group) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/groups/\(group.id)/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONEncoder().encode(["on": !group.action.on])
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchGroups()
            }
        }.resume()
    }
    
    func setBrightness(_ brightness: Int, for group: Group) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/groups/\(group.id)/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONEncoder().encode(["bri": brightness])
        
        var myGroup = self.groups.first(where: {$0.id == group.id})
        let myGroupIndex = self.groups.firstIndex(where: {$0.id == group.id})
        
        myGroup!.action.bri = brightness
        
        self.groups[myGroupIndex!] = myGroup!
        
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchGroups()
            }
        }.resume()
        
        
    }
    
    func updateGroupColor(_ group: Group, color: Color) {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let (hue, saturation, brightness) = rgbToHsb(red: components[0], green: components[1], blue: components[2])
        
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/groups/\(group.id)/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let body: [String: Any] = [
            "hue": Int(hue * 65535),
            "sat": Int(saturation * 255),
            "bri": Int(brightness * 254)
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.fetchGroups()
            }
        }.resume()
    }
}


// Add this extension to HueManager
extension HueManager {
    static var preview: HueManager {
        let manager = HueManager()
        manager.bridgeConfigurations = [
            BridgeConfiguration(name: "Bridge 1 - Living Room", bridgeIP: "192.168.1.100", apiKey: "preview1"),
            BridgeConfiguration(name: "Bridge 2 - Bedroom", bridgeIP: "192.168.1.101", apiKey: "preview2"),
            BridgeConfiguration(name: "Bridge 3 - Office", bridgeIP: "192.168.1.102", apiKey: "preview3"),
            BridgeConfiguration(name: "Bridge 4 - Kitchen", bridgeIP: "192.168.1.103", apiKey: "preview4")
        ]
        manager.currentBridgeConfig = manager.bridgeConfigurations.first
        return manager
    }
}


// Response models
private struct BridgeDiscovery: Codable {
    let id: String
    let internalipaddress: String
}

private struct BridgeResponse: Codable {
    let success: Success?
    let error: BridgeError?
    
    struct Success: Codable {
        let username: String
    }
    
    struct BridgeError: Codable {
        let type: Int
        let description: String
    }
}

private struct LightResponse: Codable {
    let name: String
    let state: HueManager.Light.State
} 
