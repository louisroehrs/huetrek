//
//  LightsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//
import SwiftUI

struct LightsView: View {
    @EnvironmentObject var hueManager: HueManager
    let borderColor: Color
    
    var body: some View {
        
        VStack {
            if let error = hueManager.error {
                NoBridgeFoundView(repeatAction: hueManager.fetchLights)
            } else {
                HStack {
                    if hueManager.currentBridgeConfig!.bridgeIP == DEMO_IP {
                        Image(systemName: "arrow.turn.left.up")
                            .foregroundColor(Color.yellow)
                            .font(.system(size: 30))
                            .padding(0)
                        Text("Click 'Demo Bridge' above to add your bridge.")
                            .textCase(.uppercase)
                            .font(Font.custom("Okuda", size: hueManager.ui.rowFontSize))
                            .foregroundColor(Color.yellow)
                            .padding(10)
                    }
                }
                List {
                    ForEach(hueManager.currentBridgeConfig!.lights) { light in
                        LightRowView(light: light)
                            .id(light.id)
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
                .onAppear{ hueManager.fetchLights()}
                
                if hueManager.currentBridgeConfig!.bridgeIP == DEMO_IP {
                    HStack {
                        Text("Select Lights, Groups, or Sensors below.")
                            .textCase(.uppercase)
                            .font(Font.custom("Okuda", size: hueManager.ui.rowFontSize))
                            .foregroundColor(Color.yellow)
                            .padding(10)
                        Image(systemName: "arrow.turn.right.down")
                            .foregroundColor(Color.yellow)
                            .font(.system(size: 30))
                            .padding(0)
                    }
                }
            }
        }
        .background(Color(hex: 0x000000))
        .overlay(
            // Left border
            Rectangle()
                .frame(width: 12)
                .foregroundColor(borderColor)
                .padding(.vertical, 0),
            alignment: .leading
        )
    }
}


struct LightRowView: View {
    @EnvironmentObject private var hueManager: HueManager
    var light: Light
    
    var body: some View {
        VStack {
            HStack(spacing: 5) {
                Text(light.name)
                    .textCase(.uppercase)
                    .offset(x:10,y:5)
                    .font(Font.custom("Okuda", size: hueManager.ui.rowFontSize))
                    .frame(width: UIScreen.main.bounds.width - 200, height: hueManager.ui.rowHeight, alignment: .leading)
                    .background(Color.blue)
                    .onTapGesture {
                        hueManager.toggleLight(light)
                    }
                
                Image(systemName: light.state.on! ? "sun.max.fill" : "sun.min")
                    .imageScale(.large)
                    .foregroundColor(light.state.on! ? .yellow : .black)
                    .frame(width:40, height: hueManager.ui.rowHeight)
                    .background(Color.black)
                    .onTapGesture {
                        hueManager.toggleLight(light)
                    }
                
                Image(systemName: "paintpalette.fill")
                    .imageScale(.large)
                    .foregroundColor(Color(hue: Double(light.state.hue!) / 65536.0, saturation: Double(light.state.sat!) / 255.0, brightness: Double(light.state.bri!) / 254.0))
                    .frame(width:40, height: hueManager.ui.rowHeight)
                    .background(Color.black)
                    .clipped()
                    .overlay
                {
                    ColorPicker(
                        "",
                        selection: Binding(
                            get: {light.selectedColor!},
                            set: {
                                hueManager.updateColor(light: light, color: $0)
                            }),
                        supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(x:20, y:20)
                    .opacity(0.10)
                    .frame(width:40, height: hueManager.ui.rowHeight)
                    .clipped()
                }
                
                RightRoundedRectangle()
                    .fill(Color(.blue))
                    .frame(width:50,height: hueManager.ui.rowHeight)
                
            }
            if light.isColorPickerVisible {
                ColorPicker("SELECT COLOR", selection: .constant(Color(hue: Double(light.state.hue!) / 65536.0, saturation: Double(light.state.sat!) / 255.0, brightness: Double(light.state.bri!) / 254.0)))
                    .font(Font.custom("Okuda", size: 30))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(20)
                RightRoundedRectangle()
                    .fill(Color( light.state.reachable ? .blue : .gray))
                    .frame(width:.infinity, height: hueManager.ui.rowHeight)
            }
        }
        .padding(.bottom, 0)
        .padding(.top,0)
        .padding(.leading, 20)
        .opacity(light.state.reachable ? 1 : 0.5)
        .background(Color.black)
        .foregroundColor(Color.black)
    }
}

