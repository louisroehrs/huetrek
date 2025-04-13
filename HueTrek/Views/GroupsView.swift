//
//  GroupsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct GroupsView: View {
    @EnvironmentObject private var hueManager: HueManager
    
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
                .foregroundColor(Color(hex: 0xCCE0F7))
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
            
            // Color picker button
            Button(action: { isColorPickerVisible.toggle() }) {
                HStack {
                    Text("Color")
                        .font(Font.custom("Okuda", size: 16))
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isColorPickerVisible ? 90 : 0))
                }
                .foregroundColor(.blue)
            }
            
            // Color picker
            if isColorPickerVisible {
                ColorPicker("Color", selection: Binding(
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
                    )) },
                    set: { newColor in
                        selectedColor = newColor
                        hueManager.updateGroupColor(group, color: newColor)
                    }
                ))
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(10)
    }
}


struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView()
            .environmentObject(HueManager())
    }
}



