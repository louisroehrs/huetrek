import Foundation
import Network
import SwiftUI
import AVFoundation // Import AVFoundation for audio playback


class HueManager: ObservableObject {
    @Published var bridgeIP: String? {
        didSet {
            if let ip = bridgeIP {
                UserDefaults.standard.set(ip, forKey: "bridgeIP")
            }
        }
    }
    @Published var apiKey: String? {
        didSet {
            if let key = apiKey {
                UserDefaults.standard.set(key, forKey: "apiKey")
            }
        }
    }
    @Published var lights: [Light] = []
    @Published var isDiscovering = false
    @Published var noDiscoveryAttempts = true
    @Published var error: String?
    
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
            var on: Bool
            var bri: Int
            var hue: Int
            var sat: Int
            var reachable: Bool
        }
    
    }
    
    init() {
        // Load saved bridge configuration
        
        //#if DEBUG
        //UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        //#endif
        
        bridgeIP = UserDefaults.standard.string(forKey: "bridgeIP")
        apiKey = UserDefaults.standard.string(forKey: "apiKey")
        
        if bridgeIP != nil && apiKey != nil {
            fetchLights()
        }
        //else {
        //    fetchLightsMock()
        // }
    }
    
    func discoverBridge() {
        isDiscovering = true
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
               } else {
                    // Fall back to UPnP discovery
                    self?.discoverBridgeUPnP()
               }
            }
        }.resume()
    }
    
    private func discoverBridgeUPnP() {
        let ssdpAddress = "239.255.255.250"
        let ssdpPort: UInt16 = 1900
        
        guard let udpSocket = try? NWConnection(
            to: NWEndpoint.hostPort(host: .init(ssdpAddress), port: .init(integerLiteral: ssdpPort)),
            using: .udp
        ) else {
            isDiscovering = false
            error = "Failed to create UDP socket"
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
            case .failed(let error):
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                    self?.isDiscovering = false
                }
            default:
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
                        self?.bridgeIP = bridgeIP
                        self?.isDiscovering = false
                    }
                }
            }
        }
        
        udpSocket.start(queue: .global())
    }
    
    func pairWithBridge() {
        guard let bridgeIP = bridgeIP else { return }
        
        print(bridgeIP)
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
                    self?.fetchLights()
                } else if let error = error {
                    self?.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func hueLightToSwiftColor(light: Light) -> Color {
        return Color(
            hue: Double(light.state.hue) / 65536.0,
            saturation: Double(light.state.sat) / 255.0,
            brightness: Double(light.state.bri) / 254.0)
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

        // Print the updated color
        print("Light \(light.name) changed to color: \(color)")
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

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("JSON Response: \(jsonString)")
                } else {
                    print("Failed to convert data to string")
                }
                
                do {
                    print(" do do do")
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                       let lights = json as? [String: Any] {
                        print("lights: \(lights)")
                        self?.lights = lights.map { (key, value) in
                            // probably a more straightforward way to assign Light.State but this works
                            let name = (value as? [String: Any])?["name"] as? String ?? ""
                            let hue = ((value as? [String: Any])?["state"] as? [String: Any])?["hue"] as? Int ?? 0
                            let on = ((value as? [String: Any])?["state"] as? [String: Any])?["on"] as? Bool ?? false
                            let bri = ((value as? [String: Any])?["state"] as? [String: Any])?["bri"] as? Int ?? 0
                            let sat = ((value as? [String: Any])?["state"] as? [String: Any])?["sat"] as? Int ?? 0
                            let state =  HueManager.Light.State(on: on, bri:bri, hue:hue, sat:sat, reachable: true)
                            // TODO: fix reachable...

                            var thisLight = Light(id: key, name: name, state: state)
                            thisLight.selectedColor = self?.hueLightToSwiftColor(light: thisLight)
                            // print(thisLight)
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
              
    func fetchLightsMock() {
        print("mock")
        let url = URL(string: "https://raw.githubusercontent.com/louisroehrs/Hue/refs/heads/main/fullconfig.json")!
        // http://localhost:8000/fullconfig.json")!
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
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                       let lights = json["lights"] as? [String: Any] {
                        self?.lights = lights.map { (key, value) in
                            // probably a more straightforward way to assign Light.State but this works
                            let name = (value as? [String: Any])?["name"] as? String ?? ""
                            let hue = ((value as? [String: Any])?["state"] as? [String: Any])?["hue"] as? Int ?? 0
                            let on = ((value as? [String: Any])?["state"] as? [String: Any])?["on"] as? Bool ?? false
                            let bri = ((value as? [String: Any])?["state"] as? [String: Any])?["bri"] as? Int ?? 0
                            let sat = ((value as? [String: Any])?["state"] as? [String: Any])?["sat"] as? Int ?? 0
                            let state =  HueManager.Light.State(on: on, bri:bri, hue:hue, sat:sat, reachable: true)
                            // fix reachable...

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
    
    func toggleColorPicker(_ light: Light) {
        playSound(sound: "colorpickerslideup")
        if let index = lights.firstIndex(where: { $0.id == light.id }) {
            lights[index].isColorPickerVisible.toggle()
        }
    }
    func toggleLight(_ light: Light) {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        print("Toggle light \(light.name)")  // Play sound
        if light.state.on {
            playSound(sound: "lightOff")
        } else {
            playSound(sound: "lightOn")
        }

        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/lights/\(light.id)/state")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try? JSONEncoder().encode(["on": !light.state.on])
        
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
