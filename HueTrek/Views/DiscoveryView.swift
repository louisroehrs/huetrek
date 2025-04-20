//
//  DiscoveryView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var hueManager: HueManager

    var body: some View {
        VStack(spacing:4) {
            HStack(spacing:4) {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text("BRIDGE")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40).padding(0)
            }.frame(maxHeight:40)
            
            VStack {
                VStack(spacing: 40) {
                    Color.clear
                    if hueManager.isDiscovering {
                        Text("Searching for Hue Bridge...")
                            .font(Font.custom("Okuda", size: 20))
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .border(Color.blue)
                            .cornerRadius(20)
                            .padding(0)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())

                    } else {
                        if !hueManager.noDiscoveryAttempts {
                            Text("NO HUE BRIDGE FOUND")
                                .font(Font.custom("Okuda Bold", size: 30))
                                .foregroundColor(.yellow)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .border(Color.yellow)
                                .cornerRadius(20)
                                .padding(0)
                        }
                        HStack(spacing:6) {
                            Button(action:hueManager.discoverBridge) {
                                Text("SEARCH FOR BRIDGE")
                                    .font(Font.custom("Okuda Bold", size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, maxHeight:60)
                            }
                            .background(Color.blue)
                            .padding(0)
                            .frame(maxWidth: .infinity)
                            
                            RightRoundedRectangle(radius:30)
                                .fill(Color.blue)
                                .frame(width:30,height:60)
                                .padding(0)
                        }.padding(0)

                    }
                       
                    Color.clear
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 40)
                .padding(.trailing,20)
                .background(Color.black)
                .listStyle(.plain)
            }
            .listStyle(.plain)
            .padding(.leading, 14)
            .padding(.top,0)
            .padding(.trailing, 0)
            .padding(.bottom, 0)
            .background(Color(hex:0xCCE0F7))
        
            // Footer
            HStack(spacing:4) {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 36)
                    .layoutPriority(1)
                Text("ABORT")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.yellow)
                    .frame(height: 40).padding(.bottom, 2)
                    .layoutPriority(1)
                    .onTapGesture {
                        hueManager.playSound(sound: "input_failed_clean")
                        hueManager.isDiscovering = false
                        hueManager.isAddingNewBridge = false
                    }
                
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:40, height:36)
            }
            .frame(maxHeight: 36)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        
    }
}

struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoveryView()
            .environmentObject(HueManager())
    }
}
