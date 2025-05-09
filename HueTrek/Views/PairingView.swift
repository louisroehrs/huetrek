//
//  PairingView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct PairingView: View {
    @EnvironmentObject var hueManager: HueManager
    
    var body: some View {
        VStack(spacing:4) {
            HStack(spacing:4) {
                TopLeftRoundedRectangle(radius: hueManager.ui.headerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: hueManager.ui.headerHeight)
                
                Text(hueManager.bridgeIP ?? "BRIDGE IP")
                    .font(Font.custom("Okuda Bold", size: hueManager.ui.headerFontSize))
                    .kerning(1.1)
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                
                Rectangle(radius: hueManager.ui.headerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40).padding(0)
            }
            .frame(maxHeight:hueManager.ui.headerHeight)
            
            VStack {
                VStack(spacing: 50) {
                    HStack(spacing:8) {
                        Text(hueManager.addBridgeState  == .connected ? "New Bridge Added" : "Press the link button on your Hue Bridge")
                            .font(Font.custom("Okuda Bold", size: 35))
                            .padding(10)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .background(.clear)
                            .kerning(1.2)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .textCase(.uppercase)
                            .frame(maxWidth:.infinity, maxHeight:100)
                    }
                    
                    VStack() {
                        GlowingImageView()
                    }
                    .padding(30)
                    .background(Color(hex:0xd0d0d0))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity, maxHeight:250)
                    .padding(40)
                    
                    HStack(spacing: 6) {
                        if hueManager.addBridgeState == .connected {
                            Rectangle()
                                .fill(Color(hex:0x9c9cff))
                                .frame(height:60)
                                .onTapGesture {
                                    hueManager.playSound(sound: "continue")
                                    hueManager.addBridgeState = .notAddingABridge
                                }
                                .overlay (alignment: .bottomTrailing){
                                    Text("CONTINUE")
                                        .font(Font.custom("Okuda Bold", size: 26))
                                        .foregroundColor(.black)
                                        .layoutPriority(1)
                                }
                        }
                        
                        else {
                            Rectangle()
                                .fill(Color(hex:0x9c9cff))
                                .frame(height:60)
                                .onTapGesture {
                                    hueManager.playSound(sound: "processing3")
                                    hueManager.pairWithBridge {
                                        hueManager.addBridgeState = .pairing
                                    }
                                }
                                .overlay (alignment: .bottomTrailing){
                                    Text("START PAIRING")
                                        .kerning(1.2)
                                        .font(Font.custom("Okuda Bold", size: 30))
                                        .foregroundColor(.black)
                                        .layoutPriority(1)
                                }
                        }
                        
                        RightRoundedRectangle(radius:30)
                            .fill(Color.blue)
                            .frame(width:30,height:60)
                            .padding(0)
                    }
                    .frame(maxHeight:60)
                }
                .padding()
                .background(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 10)
                .padding(.trailing, 0)
                .background(Color.black)
                .listStyle(.plain)
            }
            .listStyle(.plain)
            .padding(.leading, 14)
            .padding(.trailing, 0)
            .background(Color(hex:0xCCE0F7))
            
            // Footer
            HStack(spacing:4) {
                BottomLeftRoundedRectangle(radius: hueManager.ui.footerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: hueManager.ui.footerHeight)
                    .layoutPriority(1)
                
                Rectangle()
                    .fill(Color(.yellow))
                    .frame(maxHeight: hueManager.ui.footerHeight)
                    .layoutPriority(1)
                    .overlay (alignment: .bottomTrailing){
                        Text("ABORT")
                            .font(Font.custom("Okuda", size: hueManager.ui.footerButtonFontSize))
                            .kerning(1.2)
                            .foregroundColor(.black)
                            .layoutPriority(1)
                        
                    }
                    .onTapGesture {
                        hueManager.playSound(sound: "input_failed_clean")
                        hueManager.addBridgeState = .notAddingABridge
                    }
                
                Rectangle(radius: hueManager.ui.footerHeight)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:40, height:hueManager.ui.footerHeight)
            }
            .frame(maxHeight: hueManager.ui.footerHeight)
        }
        .padding()
        .background(Color.black)
    }
}

struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView()
            .environmentObject(HueManager())
    }
}
