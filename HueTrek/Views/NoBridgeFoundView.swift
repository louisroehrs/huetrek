//
//  NoBridgeFoundView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/18/25.
//  Copyright © 2025 Louis Roehrs. All rights reserved.
//  

import SwiftUI

struct NoBridgeFoundView: View {
    @EnvironmentObject private var hueManager: HueManager
    var repeatAction: () -> Void
    
    var body: some View {
        if let error = hueManager.error {
            VStack(spacing: 8) {
                Spacer()
                Text("BRIDGE NOT FOUND")
                    .textCase(.uppercase)
                    .font(Font.custom("Okuda Bold", size: 40))
                    .kerning(1.3)
                    .foregroundColor(Color(hex:0xFF0000))
                
                HStack(spacing: 6) {
                    Button(action: {
                        hueManager.error = nil
                        repeatAction()
                    }) {
                        Text("TRY AGAIN")
                            .textCase(.uppercase)
                            .font(Font.custom("Okuda Bold", size: hueManager.ui.rowFontSize))
                            .offset(x:15,y:5)
                            .kerning(1.2)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex:0xFF9C00))
                            .cornerRadius(0)
                    }
                    
                    Button(action: {
                        hueManager.error = nil
                        hueManager.showingBridgeSelector = true
                    }) {
                        Text("SELECT BRIDGE")
                            .textCase(.uppercase)
                            .font(Font.custom("Okuda Bold", size: hueManager.ui.rowFontSize))
                            .offset(x:15,y:5)
                            .kerning(1.2)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex:0xFF9C00))
                            .cornerRadius(0)

                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.black)

        }
    }
}

