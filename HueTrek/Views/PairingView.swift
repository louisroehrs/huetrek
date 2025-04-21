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
            HStack(spacing:4) {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                
                Text(hueManager.bridgeIP ?? "BRIDGE IP")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40).padding(0)
            }
            .frame(maxHeight:40)
            
            VStack {
                VStack(spacing: 50) {
                    HStack(spacing:8) {
                        Text(hueManager.newBridgeAdded ? "New Bridge Added" : "Press the link button on your Hue Bridge")
                            .font(Font.custom("Okuda Bold", size: 35))
                            .padding(10)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .background(.clear)
                            .kerning(1.2)
                            .lineLimit(nil) // unlimited lines
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
                        if hueManager.newBridgeAdded {
                            Rectangle()
                                .fill(Color(hex:0x9c9cff))
                                .frame(height:60)
                                .onTapGesture {
                                    hueManager.playSound(sound: "continue");
                                    hueManager.isAddingNewBridge = false;
                                    hueManager.newBridgeAdded = false;
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
                                        hueManager.newBridgeAdded = true
                                    }
                                }
                                .overlay (alignment: .bottomTrailing){
                                    Text("START PAIRING")
                                        .font(Font.custom("Okuda Bold", size: 26))
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
        .background(Color.black)
    }
}

struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView()
            .environmentObject(HueManager())
    }
}
