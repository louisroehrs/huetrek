//
//  GroupsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct GroupsView: View {
    @EnvironmentObject private var hueManager: HueManager
    let borderColor: Color
    
    var body: some View {
        VStack {
            
            
            List {
                ForEach(hueManager.groups) { group in
                    GroupRowView(group: group)
                        .listRowBackground(Color.black)
                        .background(Color.black)
                }
            }
            .listStyle(.plain)
            .padding(.leading, 12)
            .padding(.trailing,0)
            .scrollContentBackground(.hidden)
            .refreshable {
                hueManager.fetchGroups()
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

struct GroupRowView: View {
    @EnvironmentObject var hueManager: HueManager
    let group: HueManager.Group
    @State private var isColorPickerVisible = false
    @State private var selectedColor: Color?
    
    var body: some View {
        
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.cyan)
                .frame(height:2)
                .padding(0)
            HStack {
                VStack(alignment: .leading) {
                    Text(group.name)
                        .font(Font.custom("Okuda", size: 24))
                        .foregroundColor(.blue)
                    
                    Text("\(group.lights.count) lights • \(group.class)")
                        .font(Font.custom("Okuda", size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Power toggle button
                Button(action: { hueManager.toggleGroup(group) }) {
                    Image(systemName: group.action.on ? "power.circle.fill" : "power.circle")
                        .font(.title)
                        .foregroundColor(group.action.on ? .green : .red)
                }
            }
            
            // Brightness slider
            HStack {
                Image(systemName: "sun.min")
                    .foregroundColor(.gray)
                Slider(value: Binding(
                    get: { Double(group.action.bri) },
                    set: { hueManager.setBrightness(Int($0), for: group) }
                ), in: 0...254)
                Image(systemName: "sun.max")
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "paintpalette.fill")
                .imageScale(.large)
                .foregroundColor(Color(hue: Double(group.action.hue) / 65536.0, saturation: Double(group.action.sat) / 255.0, brightness: Double(group.action.bri) / 254.0))
                .frame(width:40, height:40)
                .background(Color.black)
                .clipped()
                .overlay
            {
                ColorPicker(
                    "",
                    selection: Binding(
                        get: { selectedColor ?? hueManager.hueLightToSwiftColor(light: HueManager.Light(
                            id: group.id,
                            name: group.name,
                            state: HueManager.Light.State(
                                on: group.action.on,
                                bri: group.action.bri,
                                hue: group.action.hue,
                                sat: group.action.sat,
                                reachable: true
                            )
                        ))
                        },
                        set: { newColor in
                            selectedColor = newColor
                            hueManager.updateGroupColor(group, color: newColor)
                        }),
                    supportsOpacity: false)
                .labelsHidden()
                .opacity(0.10)
                .frame(width:40, height: 40)
                .clipped()
            }
            
        }
        .padding()
    }
}


struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView(borderColor: Color.red)
            .environmentObject(HueManager())
    }
}



