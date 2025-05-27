//
//  DiscoveryView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var hueManager: HueManager
    @State private var glowing = false


    var body: some View {
        VStack(spacing:4) {
            HStack(spacing:4) {
                TopLeftRoundedRectangle(radius: hueManager.ui.headerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: hueManager.ui.headerHeight)
                    .layoutPriority(1)
                
                Text("BRIDGE")
                    .font(Font.custom("Okuda Bold", size: hueManager.ui.headerFontSize))
                    .kerning(1.1)
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    
                Rectangle(radius: hueManager.ui.headerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height: hueManager.ui.headerHeight).padding(0)
            }
            .frame(maxHeight: hueManager.ui.headerHeight)
            
            VStack {
                VStack(spacing: 40) {
                    Color.clear
                    
                    
                    if hueManager.addBridgeState == .scanning {
                        Text("Searching for Hue Bridge...")
                            .font(Font.custom("Okuda", size: 30))
                            .foregroundColor(.blue.opacity(glowing ? 1.0 : 0.2))
                            .padding()
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity)
                            .border(Color.blue)
                            .cornerRadius(20)
                            .padding(0)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                    glowing = true
                                }
                                hueManager.playSound(sound: "tos_bridgescanner")
                            }
                    } else {
                        if hueManager.addBridgeState == .noBridgeFound {
                            Text("NO HUE BRIDGE FOUND")
                                .font(Font.custom("Okuda Bold", size: 30))
                                .foregroundColor(.yellow)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .border(Color.yellow)
                                .cornerRadius(20)
                                .padding(0)
                        }
                        VStack(spacing:10) {
                            Text( "Make sure the hue bridge is on, it's three blue lights are lit, and connected to the same network as this device.")
                                .textCase(.uppercase)
                                .font(Font.custom("Okuda Bold", size: 30))
                                .kerning(1.3)
                                .lineLimit(7)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.green)
                                .layoutPriority(1)
                                .padding()
                            
                            
                                GlowingImageView()
                            
                            .padding(30)
                            .background(Color(hex:0xd0d0d0))
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, maxHeight:250)
                            .padding(40)
                            
                            HStack(spacing:6) {
                                Rectangle()
                                    .fill(Color(hex:0x9c9cff))
                                    .frame(height:60)
                                    .overlay (alignment: .bottomTrailing){
                                        Text("SEARCH FOR BRIDGE")
                                            .font(Font.custom("Okuda Bold", size: 30))
                                            .kerning(1.3)
                                            .foregroundColor(.black)
                                            .layoutPriority(1)
                                            .padding(3)
                                    }
                                
                                RightRoundedRectangle(radius:30)
                                    .fill(Color.blue)
                                    .frame(width:30,height:60)
                                    .padding(0)
                            }
                            .onTapGesture {
                                hueManager.discoverBridge()
                            }
                            .padding(0)
                        }
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
                BottomLeftRoundedRectangle(radius: hueManager.ui.footerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: hueManager.ui.footerHeight)
                
                if hueManager.addBridgeState == .scanning {
                    
                    
                    Rectangle()
                        .fill(Color(.yellow))
                        .frame(maxHeight:hueManager.ui.footerHeight)
                        .overlay( alignment: .trailing) {
                            Text("ABORT")
                                .font(Font.custom("Okuda Bold", size: hueManager.ui.footerButtonFontSize))
                                .kerning(1.1)
                                .textCase(.uppercase)
                                .foregroundColor(.black)
                                .padding(.bottom, -4)
                                .padding(.trailing, 1)
                        }
                        .onTapGesture {
                            hueManager.playSound(sound: "input_failed_clean")
                            if hueManager.addBridgeState == .scanning {
                                hueManager.addBridgeState = .readyToScan
                            } else {
                                hueManager.addBridgeState = .notAddingABridge
                            }
                        }
                }
                
                if hueManager.addBridgeState == .readyToScan {
                    Rectangle()
                        .fill(Color(.green))
                        .frame(maxHeight:hueManager.ui.footerHeight)
                        .overlay( alignment: .trailing) {
                            Text("EXIT")
                                .font(Font.custom("Okuda Bold", size: hueManager.ui.footerButtonFontSize))
                                .kerning(1.1)
                                .textCase(.uppercase)
                                .foregroundColor(.black)
                                .padding(.bottom, -4)
                                .padding(.trailing, 1)
                        }
                        .onTapGesture {
                            hueManager.playSound(sound: "colorpickerslidedown")
                            hueManager.addBridgeState = .notAddingABridge
                        }
                }
                
                Rectangle(radius: hueManager.ui.footerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:40, height: hueManager.ui.footerHeight)
            }
            .frame(maxHeight: hueManager.ui.footerHeight)
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
