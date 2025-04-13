//
//  LightsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//
import SwiftUI

struct LightsView: View {
    @EnvironmentObject var hueManager: HueManager
    
    var body: some View {
        
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
