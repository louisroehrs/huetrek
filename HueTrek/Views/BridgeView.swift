//
//  BridgeControlsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI
    
enum ViewType {
    case lights
    case sensors
    case groups
}

struct BridgeView: View {
    @EnvironmentObject var hueManager: HueManager
    @State var currentView: ViewType = .lights
    
    var body: some View {
        var borderColor: Color {
            switch currentView {
            case .lights:
                return Color(hex:0xED884C)
            case .sensors:
                return Color(hex:0x9c9cff)
            case .groups:
                return Color(hex:0x3399ff)
            default:
                return Color(hex:0x87eeff)
            }
        }
        
        VStack {
            HStack(spacing:3) {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(borderColor)
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text( currentView == .lights ? "LIGHTS": currentView == .sensors ? "SENSORS" : "GROUPS")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(borderColor)
                    .layoutPriority(1)
                    .kerning(1.4)
                
                Rectangle(radius: 40)
                    .fill(borderColor)
                    .frame(width:40, height:40)
                    .padding(-3)
            }
            .frame(maxHeight:40)
            
            switch currentView {
                case .lights:
                    LightsView(borderColor: borderColor).listRowSpacing(-10)
                case .sensors:
                    SensorsView(borderColor: borderColor).listRowSpacing(-10)
                case .groups:
                    GroupsView(borderColor: borderColor).listRowSpacing(-10)
            }

            // Footer
            HStack (spacing:6) {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(borderColor)
                    .frame(maxHeight: 36)
                Rectangle()
                    .fill(Color(hex:0xED884C))
                    .frame(height:36)
                    .overlay(alignment: .trailing){
                        Text("LIGHTS")
                            .font(Font.custom("Okuda Bold", size: 26))
                            .foregroundColor(.black)
                            .padding(.bottom, -4)
                            .padding(.trailing, 2)
                            .layoutPriority(1)
                            .onTapGesture {
                                hueManager.playSound(sound: "panelswitch")
                                hueManager.fetchLights()
                                withAnimation(Animation.easeInOut(duration: 0.5),
                                              { currentView = .lights}
                                )
                            }
                        
                    }
                
                Rectangle()
                    .fill(Color(hex:0x3399ff))
                    .frame(height:36)
                    .overlay(alignment: .trailing){
                        Text("GROUPS")
                            .font(Font.custom("Okuda Bold", size: 26))
                            .foregroundColor(.black)
                            .padding(.bottom, -4)
                            .padding(.trailing, 2)
                            .layoutPriority(1)
                            .onTapGesture {
                                hueManager.playSound(sound: "panelswitch")
                                hueManager.fetchGroups()
                                withAnimation(Animation.easeInOut(duration: 0.5),
                                              { currentView = .groups}
                                )
                            }
                        
                    }
                
                Rectangle()
                    .fill(Color(hex:0x9c9cff))
                    .frame(height:36)
                    .overlay(alignment: .trailing){
                        Text("SENSORS")
                            .font(Font.custom("Okuda Bold", size: 26))
                            .foregroundColor(.black)
                            .padding(.bottom, -4)
                            .padding(.trailing, 2)
                            .layoutPriority(1)
                            .onTapGesture {
                                hueManager.playSound(sound: "panelswitch")
                                hueManager.fetchSensors()
                                withAnimation(Animation.easeInOut(duration: 0.5),
                                              { currentView = .sensors}
                                )
                            }
                        
                    }
                
                Rectangle(radius: 40)
                    .fill(borderColor)
                    .frame(width:20, height:36)
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct BridgeView_Preview : PreviewProvider {
    static var previews: some View {
        BridgeView(currentView: ViewType.lights)
            .environmentObject(HueManager())
    }
}
