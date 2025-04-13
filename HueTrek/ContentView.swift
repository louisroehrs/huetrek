import SwiftUI

extension Color {
    init(hex: UInt) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}


enum ViewType {
    case lights
    case sensors
}

struct GlowingImageView: View {
    @State private var glow = false
    
    var body: some View {
        VStack {
            // Glowing background
            Image(systemName: "button.programmable")
                .font(.system(size: 100))
                .foregroundColor(.white)
                .opacity(glow ? 1.0 : 0.3)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glow)
        }

        .onAppear() {
            DispatchQueue.main.async {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                    self.glow.toggle()
                }
            }
        }
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


enum Hub: String, CaseIterable, Identifiable {
    case midrock, mardell
    var id: Self { self }
}

enum HCView: String, CaseIterable, Identifiable {
    case discovery, pairing, hub
    var id: Self { self }
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


struct TabFooter: View {
    @Binding var currentView: ViewType
    
    var body: some View {
        HStack {
            BottomLeftRoundedRectangle(radius: 36)
                .fill(Color(hex:0xCCE0F7))
                .frame(maxHeight: 36)
                .layoutPriority(1)
            
            // Lights Tab
            Text("LIGHTS")
                .font(Font.custom("Okuda", size: 50))
                .foregroundColor(currentView == .lights ? .blue : .gray)
                .frame(height: 40)
                .padding(.bottom, 2)
                .onTapGesture {
                    withAnimation {
                        currentView = .lights
                    }
                }
            
            Rectangle(radius: 40)
                .fill(Color(hex:0xCCE0F7))
                .frame(width:10, height:36)
            
            // Sensors Tab
            Text("SENSORS")
                .font(Font.custom("Okuda", size: 50))
                .foregroundColor(currentView == .sensors ? .blue : .gray)
                .frame(height:36)
                .padding(.bottom, 2)
                .onTapGesture {
                    withAnimation {
                        currentView = .sensors
                    }
                }
            
            Rectangle(radius: 40)
                .fill(Color(hex:0xCCE0F7))
                .frame(width:10, height:36)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var hueManager: HueManager
    @State private var showingPairingAlert = false
    @State private var isEditingBridgeName = false
    @State private var editedBridgeName = ""
    @State private var showingBridgeSelector = false
    @State private var isAddingNewBridge = false
    
    @State var currentView: ViewType = ViewType.lights
    
    var body: some View {
        NavigationView {
            Group {
                if isAddingNewBridge {
                    if hueManager.bridgeIP == nil {
                        discoveryView
                    } else {
                        pairingView
                    }
                } else if hueManager.currentBridgeConfig == nil {
                    discoveryView
                } else {
                    bridgeView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        BottomLeftRoundedRectangle(radius:30)
                            .fill(Color.mint)
                            .frame(width:50,height:30)
                        
                        if hueManager.bridgeIP == nil {
                            Text("SCANNING")
                                .layoutPriority(5)
                                .font(Font.custom("Okuda Bold", size: 40))
                                .foregroundStyle(Color.blue)
                                .padding(.bottom, 1)
                        } else if hueManager.apiKey == nil {
                            Text("PAIRING")
                                .font(Font.custom("Okuda Bold", size: 40))
                                .foregroundStyle(Color.blue)
                                .layoutPriority(1)
                                .padding(.bottom, 1)
                        } else {
                            if isEditingBridgeName {
                                TextField("", text: $editedBridgeName, onCommit: {
                                    hueManager.updateBridgeName(editedBridgeName)
                                    isEditingBridgeName = false
                                })
                                .font(Font.custom("Okuda Bold", size: 40))
                                .foregroundStyle(Color.blue)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 200)
                                .layoutPriority(1)
                                .padding(.bottom, 1)
                            } else {
                                Text(hueManager.currentBridgeConfig?.name ?? "BRIDGE")
                                    .font(Font.custom("Okuda Bold", size: 40))
                                    .foregroundStyle(Color.blue)
                                    .layoutPriority(1)
                                    .padding(.bottom, 1)
                                    .onTapGesture {
                                        showingBridgeSelector = true
                                    }
                            }
                        }
                        Rectangle()
                            .fill(Color.mint)
                            .frame(maxHeight:30)
                            .layoutPriority(0)
                    }
                }
            }
            .sheet(isPresented: $showingBridgeSelector) {
                BridgeSelectorView()
            }
        }
    }
    
    private var discoveryView: some View {
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text("BRIDGE")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40).padding(0)
            }.frame(maxHeight:40)
            
            VStack {
                VStack(spacing: 40) {
                    Color.clear
                    if hueManager.isDiscovering {
                        Text("Searching for Hue Bridge...")
                            .font(Font.custom("Okuda", size: 20))
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .border(Color.blue)
                            .cornerRadius(20)
                            .padding(0)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())

                    } else {
                        if !hueManager.noDiscoveryAttempts {
                            Text("NO HUE BRIDGE FOUND")
                                .font(Font.custom("Okuda Bold", size: 30))
                                .foregroundColor(.yellow)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .border(Color.yellow)
                                .cornerRadius(20)
                                .padding(0)
                        }
                        HStack(spacing:-5) {
                            Button(action:hueManager.discoverBridge) {
                                Text("SEARCH FOR BRIDGE")
                                    .font(Font.custom("Okuda Bold", size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, maxHeight:60)
                            }
                            .background(Color.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            
                            RightRoundedRectangle(radius:30)
                                .fill(Color.blue)
                                .frame(width:30,height:60)
                                .padding(0)
                        }.padding(0)

                    }
                       
                    Color.clear
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 40)
                .padding(.trailing,20)
                .background(Color.black)
                .listStyle(.plain)
            }
            .listStyle(.plain)
            .padding(.leading, 14)
            .padding(.top,0)
            .padding(.trailing, 0)
            .padding(.bottom, 0)
            .background(Color(hex:0xCCE0F7))
        
            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 36)
                    .layoutPriority(1)
                Text("RETRY")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height: 40).padding(.bottom, 2)
                    .layoutPriority(1)
                
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:40, height:36)
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        
    }
    
    private var pairingView: some View {
        
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text(hueManager.bridgeIP ?? "BRIDGE IP")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    .frame(minWidth: 180)
                    
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40).padding(0)
            }.frame(maxHeight:40)
            
            VStack {
                VStack(spacing: 50) {
                    HStack(spacing:8) {
                        /*                        TopLeftRoundedRectangle()
                         .fill(.mint)
                         .frame(width:40,height:95)
                         .padding(0)
                         */
                        Text("Press the link button on your Hue Bridge")
                            .font(Font.custom("Okuda Bold", size: 35))
                            .padding(10)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .background(.clear)
                            .frame(maxWidth:.infinity, maxHeight:100)
                    }
                    HStack() {
                  
                        VStack() {
                            GlowingImageView()
                        }
                        .padding(30)
                        .background(Color(hex:0xd0d0d0))
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity, maxHeight:250)
                        .padding(40)
                    }
                    .frame(maxWidth: .infinity, maxHeight:250)
                
                    HStack(spacing:-5) {
                        Button(action: {
                            hueManager.pairWithBridge {
                                // Handle completion if needed
                            }
                        }) {
                            Text("START PAIRING")
                                .font(Font.custom("Okuda Bold", size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight:60)
                        }
                        .background(Color.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        
                        RightRoundedRectangle(radius:30)
                            .fill(Color.blue)
                            .frame(width:30,height:60)
                            .padding(0)
                    }.padding(0)
                }
                .padding()
                .background(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 10)
                .padding(.trailing, 0)
                .background(Color.black)
                .listStyle(.plain)
            }
            .listStyle(.plain)
            .padding(.leading, 14)
            .padding(.top,0)
            .padding(.trailing, 0)
            .padding(.bottom, 0)
            .background(Color(hex:0xCCE0F7))
        
            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 36)
                    .layoutPriority(1)
                Text("RETRY")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.red)
                    .frame(height: 40).padding(.bottom, 2)
                    .layoutPriority(1)
                    .onTapGesture {
                        hueManager.bridgeIP = nil
                    }
                
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:40, height:36)
            }
        }
        .padding()
        .background(Color.black).edgesIgnoringSafeArea(.all)

    }
    
    private var bridgeView: some View {
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text(currentView == .lights ? "LIGHTS": "SENSORS")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40)
                    .padding(0)
            }
            .frame(maxHeight:40)
            
            lightListView.background(Color.red).listRowSpacing(-10)

                    
            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 36)
                Text("LIGHTS")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height: 40)
                    .padding(.bottom, 2)
                    .onTapGesture {
                        currentView = .lights
                    }
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
                Text("SWITCHES")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height:36)
                    .padding(.bottom, 2)
                    .onTapGesture {
                        currentView = .sensors
                    }
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
            } 
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))

    }
    
    private var lightListView: some View {

        VStack {
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

struct BridgeSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var hueManager: HueManager
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var editingBridgeId: UUID?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(hueManager.bridgeConfigurations) { config in
                    HStack {
                        if isEditingName && editingBridgeId == config.id {
                            TextField("Bridge Name", text: $editedName, onCommit: {
                                if editingBridgeId == hueManager.currentBridgeConfig?.id {
                                    hueManager.updateBridgeName(editedName)
                                }
                                isEditingName = false
                                editingBridgeId = nil
                            })
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(config.name)
                                .font(Font.custom("Okuda", size: 24))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if config.id == hueManager.currentBridgeConfig?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hueManager.switchToBridge(withId: config.id)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .contextMenu {
                        Button("Rename") {
                            editingBridgeId = config.id
                            editedName = config.name
                            isEditingName = true
                        }
                        Button("Delete", role: .destructive) {
                            hueManager.removeBridge(withId: config.id)
                        }
                    }
                }
            }
            .navigationTitle("Select Bridge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SensorRowView: View {
    let sensor: HueManager.Sensor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(sensor.name)
                        .font(Font.custom("Okuda", size: 24))
                        .foregroundColor(.blue)
                    
                    Text(sensor.type)
                        .font(Font.custom("Okuda", size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Battery indicator
                HStack(spacing: 2) {
                    Image(systemName: "battery.100")
                        .foregroundColor(sensor.config.battery > 20 ? .green : .red)
                    Text("\(sensor.config.battery)%")
                        .font(Font.custom("Okuda", size: 14))
                        .foregroundColor(.gray)
                }
                
                // Connection status
                Circle()
                    .fill(sensor.config.reachable ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
            }
            
            if let lastUpdated = sensor.state.lastupdated {
                Text("Last Updated: \(lastUpdated)")
                    .font(Font.custom("Okuda", size: 14))
                    .foregroundColor(.gray)
            }
            
            if let rotaryEvent = sensor.state.rotaryevent {
                Text("Rotary Event: \(rotaryEvent)")
                    .font(Font.custom("Okuda", size: 14))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(10)
    }
}

struct SensorsView: View {
    @EnvironmentObject private var hueManager: HueManager
    
    var body: some View {
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text("SENSORS")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40)
                    .padding(0)
            }
            .frame(maxHeight:40)
            
            List {
                ForEach(hueManager.sensors) { sensor in
                    SensorRowView(sensor: sensor)
                        .listRowBackground(Color.black)
                        .background(Color.black)
                }
            }
            .listStyle(.plain)
            .padding(.leading, 12)
            .scrollContentBackground(.hidden)
            .refreshable {
                hueManager.fetchSensors()
            }
            
            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 36)
                    .layoutPriority(1)
                Text("LIGHTS")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height: 40)
                    .padding(.bottom, 2)
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
                Text("SENSORS")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height:36)
                    .padding(.bottom, 2)
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            hueManager.fetchSensors()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HueManager())
} 
