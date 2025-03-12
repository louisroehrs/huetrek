import SwiftUI

struct TopLeftRoundedRectangle: Shape {
    var radius: CGFloat = 30  // Adjust corner radius

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

struct Rectangle: Shape {
    var radius: CGFloat = 30  // Adjust corner radius

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

struct BottomLeftRoundedRectangle: Shape {
    var radius: CGFloat = 30  // Adjust corner radius

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY ))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(90),
                    clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

struct ContentView: View {
    @EnvironmentObject private var hueManager: HueManager
    @State private var showingPairingAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if hueManager.bridgeIP == nil {
                    lightsView
                    // discoveryView
                } else if hueManager.apiKey == nil {
                    pairingView
                } else {
                    lightsView
                }
            }
//            .navigationTitle("Hue Control")
            .alert("Error", isPresented: .constant(hueManager.error != nil)) {
                 Button("OK") {
                    hueManager.error = nil
                 }
            } message: {
                 Text(hueManager.error ?? "")
                    
            }
        }
    }
    
    
    
    private var lightsView: some View {
    
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color.blue)
                    .frame(width: 200, height: 40)
                
                Text("LIGHTS")
                    .font(Font.custom("Okuda Bold", size: 57))
                    .padding(0)
                    .frame( maxWidth: UIScreen.main.bounds.width)
                    .foregroundColor(.blue)
                    
                Rectangle(radius: 40).fill(Color.blue).frame(width:60, height:40).padding(0)
            }
            .frame(maxHeight:40)
            // Lights List
            lightListView.background(Color.red)

            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 40)
                    .fill(Color.blue)
                    .frame(maxWidth: UIScreen.main.bounds.width/2, maxHeight: 40)
                Text("LIGHTS")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.white)
                    .frame(height: 40).padding(0)
                Rectangle(radius: 40).fill(Color.blue).frame(width:10, height:40)
                Text("SENSORS")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.white)
                    .frame(height:40)
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private var discoveryView: some View {
        VStack(spacing: 20) {
            if hueManager.isDiscovering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Searching for Hue Bridge...")
            } else {
                Text("No Hue Bridge found")
                    .font(.headline)
                Button("Search for Bridge") {
                    hueManager.discoverBridge()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private var pairingView: some View {
        VStack(spacing: 20) {
            Text("Press the link button on your Hue Bridge")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Image(systemName: "button.programmable")
                .font(.system(size: 50))
            
            Button("Start Pairing") {
                hueManager.pairWithBridge()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Start Over", role: .destructive) {
                hueManager.bridgeIP = nil
            }
        }
        .padding()
    }
    
    private var lightListView: some View {
        VStack {
            // Color Picker
            ColorPicker("Select Color", selection: .constant(Color.blue))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.8))
                .cornerRadius(40)

            // Brightness Slider
            HStack {
                Text("Brightness")
                Slider(value: .constant(0.5), in: 0...1)
                    .accentColor(.yellow)
            }
            .padding()

            List {
                ForEach(hueManager.lights) { light in
                    LightRowView(light: light)
                }
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                hueManager.fetchLights()
            }
//            .toolbar {
//                Button("Reset", role: .destructive) {
//                    UserDefaults.standard.removeObject(forKey: "bridgeIP")
//                    UserDefaults.standard.removeObject(forKey: "apiKey")
//                    hueManager.bridgeIP = nil
//                    hueManager.apiKey = nil
//                }
//            }
        }
        .background(Color.blue)
    }
        

}

struct LightRowView: View {
    @EnvironmentObject private var hueManager: HueManager
    let light: HueManager.Light
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: light.state.on ? "lightbulb.fill" : "lightbulb")
                    .foregroundColor(light.state.on ? .yellow : .gray)
                Text(light.name)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: .init(
                    get: { light.state.on },
                    set: { _ in hueManager.toggleLight(light) }
                ))
            }
            
            if light.state.on, let brightness = light.state.bri {
                Slider(
                    value: .init(
                        get: { Double(brightness) },
                        set: { hueManager.setBrightness(Int($0), for: light) }
                    ),
                    in: 0...254
                )
            }
        }
        .opacity(light.state.reachable ? 1 : 0.5)
    }
        
}

#Preview {
    ContentView()
        .environmentObject(HueManager())
} 
