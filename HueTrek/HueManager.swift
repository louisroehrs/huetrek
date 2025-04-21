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
    
    @Published var sensors: [Sensor] = []
        
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
    
    init() {
        // Load saved bridge configurations
        if let data = UserDefaults.standard.data(forKey: "bridgeConfigurations"),
           let decoded = try? JSONDecoder().decode([BridgeConfiguration].self, from: data) {
            self.bridgeConfigurations = decoded
        } else {
            self.bridgeConfigurations = []
        }
        
        // Load current bridge configuration
        if let currentBridgeId = UserDefaults.standard.string(forKey: "currentBridgeId"),
           let uuid = UUID(uuidString: currentBridgeId),
           let config = bridgeConfigurations.first(where: { $0.id == uuid }) {
            self.currentBridgeConfig = config
        } else {
            self.currentBridgeConfig = nil
        }
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
            "on": light.state.on, // Keep the current on/off state
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
        print("url \(url)")
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                print("dispatch")
                if let error = error {
                    self?.error = error.localizedDescription
                    print(self?.error ?? "Unknown error")
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    print(self?.error ?? "Unknown error")
                    return
                }
/*
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("JSON Response: \(jsonString)")
                } else {
                    print("Failed to convert data to string")
                }
 */
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                        self?.lights = json.compactMap { (key, value) -> Light? in
                            guard let lightData = value as?[String: Any],
                                  let name = lightData["name"] as? String,
                                  let stateData = lightData["state"] as? [String: Any]
                            else {
                                return nil
                            }
                                    
                            let state =  Light.State(
                                on:  stateData["on"] as? Bool ?? false,
                                bri: stateData["bri"] as? Int ?? 0,
                                hue: stateData["hue"] as? Int ?? 0,
                                sat: stateData["sat"] as? Int ?? 0,
                                reachable: true)
                            // TODO: fix reachable...
                                    
                        

                            var thisLight = Light(id: key, name: name, state: state)
                            thisLight.selectedColor = self?.hueLightToSwiftColor(light: thisLight)

                            return thisLight
                        }
                        self?.lights.sort { $0.name < $1.name }
                    }
                } catch {
                    self?.error = error.localizedDescription
                    print(self?.error ?? "Json parsing error")
                }
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
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                        self?.sensors = json.compactMap { (key, value) -> Sensor? in
                            guard let sensorData = value as? [String: Any],
                                  let name = sensorData["name"] as? String,
                                  let type = sensorData["type"] as? String,
                                  let manufacturer = sensorData["manufacturername"] as? String,
                                  let productName = sensorData["productname"] as? String,
                                  let stateData = sensorData["state"] as? [String: Any],
                                  let configData = sensorData["config"] as? [String: Any],
                                  let on = configData["on"] as? Bool,
                                  let battery = configData["battery"] as? Int,
                                  let reachable = configData["reachable"] as? Bool else {
                                return nil
                            }
                            
                            let state = Sensor.SensorState(
                                rotaryevent: stateData["rotaryevent"] as? Int,
                                expectedrotation: stateData["expectedrotation"] as? Int,
                                expectedeventduration: stateData["expectedeventduration"] as? Int,
                                lastupdated: stateData["lastupdated"] as? String
                            )
                            
                            let config = Sensor.SensorConfig(
                                on: on,
                                battery: battery,
                                reachable: reachable
                            )
                            
                            return Sensor(
                                id: key,
                                name: name,
                                type: type,
                                manufacturername: manufacturer,
                                productname: productName,
                                state: state,
                                config: config
                            )
                        }
                        self?.sensors.sort { $0.name < $1.name }
                    }
                } catch {
                    self?.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func fetchGroups() {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/groups")!
        // let url = URL(string: "https://raw.githubusercontent.com/louisroehrs/Hue/refs/heads/main/groupsconfig.json")!
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                        self?.groups = json.compactMap { (key, value) -> Group? in
                            guard let groupData = value as? [String: Any],
                                  let name = groupData["name"] as? String,
                                  let lights = groupData["lights"] as? [String],
                                  let type = groupData["type"] as? String,
                                  var stateData = groupData["state"] as? [String: Any],
                                  var actionData = groupData["action"] as? [String: Any],
                                  let className = groupData["class"] as? String else {
                                return nil
                            }
                            
                            let state = Group.GroupState(
                                all_on: stateData["all_on"] as? Bool ?? false,
                                any_on: stateData["any_on"] as? Bool ?? false
                            )
                            
                            let action = Group.GroupAction(
                                on: actionData["on"] as? Bool ?? false,
                                bri: actionData["bri"] as? Int ?? 0,
                                hue: actionData["hue"] as? Int ?? 0,
                                sat: actionData["sat"] as? Int ?? 0,
                                effect: actionData["effect"] as? String,
                                xy: actionData["xy"] as? [Double],
                                ct: actionData["ct"] as? Int,
                                alert: actionData["alert"] as? String,
                                colormode: actionData["colormode"] as? String
                            )
                            
                            return Group(
                                id: key,
                                name: name,
                                lights: lights,
                                type: type,
                                state: state,
                                action: action,
                                class: className
                            )
                        }
                        self?.groups.sort { $0.name < $1.name }
                    }
                } catch {
                    self?.error = error.localizedDescription
                }
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
        var myGroupIndex = self.groups.firstIndex(where: {$0.id == group.id})

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
