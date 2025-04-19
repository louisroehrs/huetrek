//
//  ContentView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

extension Color {
    init(hex: UInt) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
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

struct ContentView: View {
    @EnvironmentObject private var hueManager: HueManager
    @State private var showingPairingAlert = false
    @State private var isEditingBridgeName = false
    @State private var editedBridgeName = ""
    @State private var showingBridgeSelector = false
    
    @State var currentView: ViewType = ViewType.lights
    
    var body: some View {
        NavigationView {
            Group {
                if hueManager.isAddingNewBridge {
                    if hueManager.bridgeIP == nil {
                        AnyView(DiscoveryView())
                    } else {
                        AnyView(PairingView())
                    }
                } else if hueManager.currentBridgeConfig == nil {
                    AnyView(DiscoveryView())
                } else {
                    AnyView(BridgeView())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .foregroundStyle(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        BottomLeftRoundedRectangle(radius:30)
                            .fill(Color(hex:0xFF9C00))
                            .frame(width:50,height:30)
                        if hueManager.bridgeIP == nil {
                            Text("SCANNING")
                                .layoutPriority(1)
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
                                    .textCase(.uppercase)
                                    .font(Font.custom("Okuda Bold", size: 40))
                                    .foregroundStyle(Color.blue)
                                    .padding(.bottom, 1)
                                    .onTapGesture {
                                        hueManager.playSound(sound: "colorpickerslideup")
                                        showingBridgeSelector = true
                                    }
                                    .layoutPriority(1)
                            }
                        }
                        Rectangle()
                            .fill(Color(hex:0xFF9C00))
                            .frame(minWidth:40)
                    }
                    .frame(maxHeight:30)
                }
            }
            .sheet(isPresented: $showingBridgeSelector) {
                BridgeSelectorView()
            } 
        }
    }
}



#Preview {
    ContentView()
        .environmentObject(HueManager())
} 
