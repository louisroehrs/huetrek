import SwiftUI



extension Color {
    init(hex: UInt) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

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

struct RightRoundedRectangle: Shape {
    var radius: CGFloat = 20  // Adjust corner radius

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX+radius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
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
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(UIScreen.main.bounds.width)")
                        .font(.largeTitle) // Set the font size
                        .foregroundColor(.white) // Set the text color to white
                    }
                }
            .alert("Error", isPresented: .constant(hueManager.error != nil)) {
                 Button("OK") {
                    hueManager.error = nil
                 }
            } message: {
                 Text(hueManager.error ?? "")
                    
            }
            .foregroundStyle(Color.white)

        }
    }
    
    private var lightsView: some View {
    
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width: 200, height: 40)
                
                Text("LIGHTS")
                    .font(Font.custom("Okuda Bold", size: 57))
                    .padding(0)
                    .frame( maxWidth: UIScreen.main.bounds.width)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:60, height:40).padding(0)
            }
            .frame(maxHeight:40)
            // Lights List
            lightListView.background(Color.red).listRowSpacing(-10)

            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxWidth: UIScreen.main.bounds.width/2, maxHeight: 36)
                Text("LIGHTS")
                    .font(Font.custom("Okuda", size: 52))
                    .foregroundColor(.blue)
                    .frame(height: 40).padding(0)
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:10, height:36)
                Text("SENSORS")
                    .font(Font.custom("Okuda", size: 52))
                    .foregroundColor(.blue)
                    .frame(height:36)
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:10, height:36)
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
           /* ColorPicker("Select Color", selection: .constant(Color.blue))
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
*/
            List {
                ForEach(hueManager.lights) { light in
                    
                    LightRowView(light: light)
                        .listRowBackground(Color.black)
                        .background(Color.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .listStyle(.plain)
            .padding(.leading, 12)
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
        .background(Color(hex: 0xCCE0F7))
    }
        

}

struct LightRowView: View {
    @EnvironmentObject private var hueManager: HueManager
    var light: HueManager.Light
    
    
    var body: some View {
        VStack {
            HStack(spacing: 1) {
                
                Text(light.name)
                    .textCase(.uppercase)
                    .offset(x:10,y:5)
                    .font(Font.custom("Okuda", size: 30))
                    .frame(width: UIScreen.main.bounds.width - 180, height:40, alignment: .leading)
                    .background(Color.blue)
                    .onTapGesture {
                        hueManager.toggleLight(light)
                    }
                
                Image(systemName: light.state.on ? "sun.max.fill" : "sun.min")
                    .imageScale(.large)
                    .foregroundColor(light.state.on ? .yellow : .black)
                    .frame(width:40, height:40)
                    .background(Color.black)
                    .onTapGesture {
                        hueManager.toggleLight(light)
                    }
                
                
                Image(systemName: "paintpalette.fill")
                    .imageScale(.large)
                    .foregroundColor(Color(hue: Double(light.state.hue) / 65536.0, saturation: Double(light.state.sat) / 255.0, brightness: Double(light.state.bri) / 254.0))
                    .frame(width:40, height:40)
                    .background(Color.black)
                    .clipped()
                    .overlay
                        {
                            ColorPicker(
                                "",
                                selection: Binding(
                                    get: {light.selectedColor! ?? Color.white},
                                    set: {
                                        hueManager.updateColor(light: light, color: $0)
                                    }),
                                supportsOpacity: false)
                            .labelsHidden()
                            .scaleEffect(x:20, y:20)
                            .opacity(0.10)
                            .frame(width:40, height: 40)
                            .clipped()
                        }
                
                RightRoundedRectangle()
                    .fill(Color(.blue))
                    .frame(width:40,height:40)
                
            }
            if light.isColorPickerVisible {
                ColorPicker("SELECT COLOR", selection: .constant(Color(hue: Double(light.state.hue) / 65536.0, saturation: Double(light.state.sat) / 255.0, brightness: Double(light.state.bri) / 254.0)))
                    .font(Font.custom("Okuda", size: 30))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(20)
                RightRoundedRectangle()
                    .fill(Color(.blue))
                    .frame(width:.infinity, height:40)
                
            }
        }
        .padding(.bottom, 0)
        .padding(.top,0)
        .padding(.leading, 8)
        .opacity(light.state.reachable ? 1 : 0.5)
        .background(Color.black)
        .foregroundColor(Color.black)
    }

}

#Preview {
    ContentView()
        .environmentObject(HueManager())
} 
