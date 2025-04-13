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
        VStack {
            HStack {// Header
                TopLeftRoundedRectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 40)
                    .layoutPriority(1)
                
                Text(hueManager.bridgeIP ?? "BRIDGE IP")
                    .font(Font.custom("Okuda Bold", size: 55))
                    .padding(.bottom,2)
                    .foregroundColor(Color(hex:0xCCE0F7))
                    .layoutPriority(1)
                    .frame(minWidth: 180)
                
                Rectangle(radius: 40)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(width:60, height:40).padding(0)
            }.frame(maxHeight:40)
            
            VStack {
                VStack(spacing: 50) {
                    HStack(spacing:8) {
                        /*                        TopLeftRoundedRectangle()
                         .fill(.mint)
                         .frame(width:40,height:95)
                         .padding(0)
                         */
                        Text("Press the link button on your Hue Bridge")
                            .font(Font.custom("Okuda Bold", size: 35))
                            .padding(10)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .background(.clear)
                            .frame(maxWidth:.infinity, maxHeight:100)
                    }
                    HStack() {
                        
                        VStack() {
                            GlowingImageView()
                        }
                        .padding(30)
                        .background(Color(hex:0xd0d0d0))
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity, maxHeight:250)
                        .padding(40)
                    }
                    .frame(maxWidth: .infinity, maxHeight:250)
                    
                    HStack(spacing:-5) {
                        Button(action: {
                            hueManager.pairWithBridge {
                                // Handle completion if needed
                            }
                        }) {
                            Text("START PAIRING")
                                .font(Font.custom("Okuda Bold", size: 30))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight:60)
                        }
                        .background(Color.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        
                        RightRoundedRectangle(radius:30)
                            .fill(Color.blue)
                            .frame(width:30,height:60)
                            .padding(0)
                    }.padding(0)
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
            .padding(.top,0)
            .padding(.trailing, 0)
            .padding(.bottom, 0)
            .background(Color(hex:0xCCE0F7))
            
            // Footer
            HStack {
                BottomLeftRoundedRectangle(radius: 36)
                    .fill(Color(hex:0xCCE0F7))
                    .frame(maxHeight: 36)
                    .layoutPriority(1)
                Text("RETRY")
                    .font(Font.custom("Okuda", size: 50))
                    .foregroundColor(.red)
                    .frame(height: 40).padding(.bottom, 2)
                    .layoutPriority(1)
                    .onTapGesture {
                        hueManager.bridgeIP = nil
                    }
                
                Rectangle(radius: 40).fill(Color(hex:0xCCE0F7)).frame(width:40, height:36)
            }
        }
        .padding()
        .background(Color.black).edgesIgnoringSafeArea(.all)
        
    }
}

struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView()
            .environmentObject(HueManager())
    }
}
