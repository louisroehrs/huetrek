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
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text( currentView == .lights ? "LIGHTS": currentView == .sensors ? "SENSORS" : "GROUPS")
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
            
            switch currentView {
                case .lights:
                    LightsView().listRowSpacing(-10)
                case .sensors:
                    SensorsView().listRowSpacing(-10)
                case .groups:
                    GroupsView().listRowSpacing(-10)
            }

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
                    .layoutPriority(1)
                    .onTapGesture {
                        withAnimation(Animation.easeInOut(duration: 0.5),
                            { currentView = .lights}
                        )
                    }
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
                Text("GROUPS")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height:36)
                    .padding(.bottom, 2)
                    .layoutPriority(1)
                    .onTapGesture {
                        withAnimation(Animation.easeInOut(duration: 0.5), 
                            { currentView = .groups}
                        )
                    }
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
                Text("SW")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.blue)
                    .frame(height:36)
                    .padding(.bottom, 2)
                    .layoutPriority(1)
                    .onTapGesture {
                        withAnimation(Animation.easeInOut(duration: 0.5), 
                            { currentView = .sensors}
                        )
                    }
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:10, height:36)
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
