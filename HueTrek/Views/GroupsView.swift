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
                        .padding(.top, 20)
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
            HStack(spacing: 6) {
                TopLeftRoundedRectangle(radius: hueManager.ui.footerHeight)
                    .fill(Color.cyan)
                    .frame(maxWidth: .infinity, maxHeight: hueManager.ui.footerHeight)
                    .overlay(alignment: .leading) {
                        Text(group.name)
                            .font(Font.custom("Okuda", size: hueManager.ui.footerLabelFontSize))
                            .kerning(1.2)
                            .foregroundColor(.cyan)
                            .textCase(.uppercase)
                            .padding(.leading, 5)
                            .background(Color.black)
                            .offset(x:40,y:0)
                    }
                
                Button(action: {
                    hueManager.toggleGroup(group)
                    hueManager.playSound(sound: "light" + (group.action.on ? "Off" : "On"))
                }) {
            Image(systemName: group.action.on ? "power.circle.fill" : "power.circle")
                        .font(.title)
                        .foregroundColor(group.action.on ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: hueManager.ui.footerHeight)
            
            VStack(){
                HStack(spacing:3) {

                    Text("\(group.lights.count)")
                        .font(Font.custom("Okuda", size: 36))
                        .foregroundColor(.gray)
                        .padding(.leading)
                    Text((group.lights.count > 1) ? " lights " : " light ")
                        .font(Font.custom("Okuda", size: 24))
                        .textCase(.uppercase)
                        .offset(x:0,y:3)
                        .foregroundColor(.black)
                        .background(Color.gray)
                    Text("\(group.action.bri)")
                        .font(Font.custom("Okuda", size: 36))
                        .foregroundColor(.gray)
                        .padding(0)
                    Text(" b ")
                        .font(Font.custom("Okuda", size: 24))
                        .textCase(.uppercase)
                        .offset(x:0,y:3)
                        .foregroundColor(.black)
                        .background(Color.gray)
                    Text("\(group.action.hue)".replacing(",", with:""))
                        .font(Font.custom("Okuda", size: 36))
                        .foregroundColor(.gray)
                        .padding(0)
                    Text(" h ")
                        .font(Font.custom("Okuda", size: 24))
                        .textCase(.uppercase)
                        .offset(x:0,y:3)
                        .foregroundColor(.black)
                        .background(Color.gray)
                    Text("\(group.action.sat)")
                        .font(Font.custom("Okuda", size: 36))
                        .foregroundColor(.gray)
                        .padding(0)
                    
                    Text(" s ")
                        .font(Font.custom("Okuda", size: 24))
                        .textCase(.uppercase)
                        .offset(x:0,y:3)
                        .foregroundColor(.black)
                        .background(Color.gray)
                    Spacer()
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
                .frame(maxWidth: .infinity, maxHeight:40)
                .padding(.trailing,0)
                
                HStack {
                    Image(systemName: "sun.min")
                        .foregroundColor(.gray)
                    GroupSliderView(sliderValue: Binding(
                        get: {
                            Double(group.action.bri)
                        },
                        set: { sliderValue in
                            var myGroup = hueManager.groups.first(where: {$0.id == group.id} )
                            var myGroupIndex = hueManager.groups.firstIndex(where: {$0.id == group.id} )
                            myGroup!.action.bri = Int(sliderValue)
                            hueManager.groups[myGroupIndex!] = myGroup!
                        }
                    ),
                    group: group)
                    Image(systemName: "sun.max")
                        .foregroundColor(.gray)
                }
                .padding()
                
                
            }
            .padding(.leading, 10)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.cyan)
                    .frame(width: 5)
            }
            BottomLeftRoundedRectangle(radius: 20)
                .fill(.cyan)
                .frame(height: 20)
                
        }
        .padding(0)
    }
}


struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView(borderColor: Color.red)
            .environmentObject(HueManager())
    }
}



