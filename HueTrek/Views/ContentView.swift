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

struct ContentViewTitleText: View {
    var text: String = "text"
    
    init(_ text: String) {
            self.text = text
    }

    var body: some View {
        Text(text)
            .layoutPriority(1)
            .font(Font.custom("Okuda Bold", size: 40))
            .textCase(.uppercase)
            .kerning(1.1)
            .foregroundStyle(Color.blue)
            .padding(.bottom, 1)
    }
}


struct ContentView: View {
    @EnvironmentObject private var hueManager: HueManager
    @State private var isEditingBridgeName = false
    @State private var editedBridgeName = ""

    var body: some View {
        NavigationStack {
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
                    HStack(spacing:4) {
                        BottomLeftRoundedRectangle(radius:30)
                            .fill(Color(hex:0xFF9C00))
                            .frame(width:50,height:30)

                        if hueManager.bridgeIP == nil {
                            ContentViewTitleText("SCANNING")
                        } else if hueManager.isAddingNewBridge {
                            ContentViewTitleText("PAIRING")
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
                                ContentViewTitleText(hueManager.currentBridgeConfig?.name ?? "BRIDGE")
                                    .onTapGesture {
                                        hueManager.playSound(sound: "colorpickerslideup")
                                        hueManager.showingBridgeSelector = true
                                    }
                            }
                        }
                        Rectangle()
                            .fill(Color(hex:0xFF9C00))
                            .frame(minWidth:40)
                            .padding(0)
                    }
                    .frame(maxWidth:.infinity, maxHeight:30)
                    .padding(0)
                }                
            }
            .sheet(isPresented: $hueManager.showingBridgeSelector) {
                BridgeSelectorView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HueManager())
} 

