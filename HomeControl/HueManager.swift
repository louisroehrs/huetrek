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
        bridgeIP = UserDefaults.standard.string(forKey: "bridgeIP")
        apiKey = UserDefaults.standard.string(forKey: "apiKey")
        
        if bridgeIP != nil && apiKey != nil {
            fetchLights()
        }
        fetchLightsMock()
    }
    
    func discoverBridge() {
        isDiscovering = true
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
    
    func fetchLights() {
        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        
        let url = URL(string: "http://\(bridgeIP)/api/\(apiKey)/lights")!
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let lightsDict = try? JSONDecoder().decode([String: LightResponse].self, from: data) {
                    self?.lights = lightsDict.map { Light(id: $0.key,
                                                        name: $0.value.name,
                                                        state: $0.value.state) }

                    self?.lights.sort { $0.name < $1.name }
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
        print("Light \(light.name) changed to color: \(color)")
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
//        guard let bridgeIP = bridgeIP, let apiKey = apiKey else { return }
        print("Toggle light \(light.name)")  // Play sound
        if light.state.on {
            playSound(sound: "lightOff")
        } else {
            playSound(sound: "lightOn")
        }

        let bridgeIP = "localhost:8000"
        let apiKey = "apiKey"
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
