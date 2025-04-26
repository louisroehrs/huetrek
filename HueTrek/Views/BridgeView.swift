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
            }
        }
        
        VStack {
            HStack(spacing:3) {
                TopLeftRoundedRectangle(radius: hueManager.ui.headerHeight)
                    .fill(borderColor)
                    .frame(maxHeight: hueManager.ui.headerHeight)
                    .layoutPriority(1)
                
                Text( currentView == .lights ? "LIGHTS": currentView == .sensors ? "SENSORS" : "GROUPS")
                    .font(Font.custom("Okuda Bold", size: hueManager.ui.headerFontSize))
                    .kerning(2)
                    .padding(.bottom,2)
                    .foregroundColor(borderColor)
                    .layoutPriority(1)
                
                Rectangle(radius: hueManager.ui.headerHeight)
                    .fill(borderColor)
                    .frame(width:40, height: hueManager.ui.headerHeight)
                    .padding(-3)
            }
            .frame(maxHeight: hueManager.ui.headerHeight)
            
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
                BottomLeftRoundedRectangle(radius: hueManager.ui.footerHeight)
                    .fill(borderColor)
                    .frame(maxHeight: hueManager.ui.footerHeight)
                Rectangle()
                    .fill(Color(hex:0xED884C))
                    .frame(height: hueManager.ui.footerHeight)
                    .overlay(alignment: .trailing){
                        Text("LIGHTS")
                            .font(Font.custom("Okuda Bold", size: hueManager.ui.footerButtonFontSize))
                            .kerning(1.2)
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
                    .frame(height: hueManager.ui.footerHeight)
                    .overlay(alignment: .trailing){
                        Text("GROUPS")
                            .font(Font.custom("Okuda Bold", size: hueManager.ui.footerButtonFontSize))
                            .kerning(1.2)
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
                    .frame(height: hueManager.ui.footerHeight)
                    .overlay(alignment: .trailing){
                        Text("SENSORS")
                            .font(Font.custom("Okuda Bold", size: hueManager.ui.footerButtonFontSize))
                            .kerning(1.2)
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
                
                Rectangle(radius: hueManager.ui.footerHeight)
                    .fill(borderColor)
                    .frame(width:20, height:hueManager.ui.footerHeight)
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
