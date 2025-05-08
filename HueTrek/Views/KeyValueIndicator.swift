//
//  KeyValueIndicator.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/26/25.
//

import SwiftUI

struct KeyValueIndicator: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack(spacing:4) {
            Rectangle()
                .fill(Color.black)
                .frame(width: 90, height:30)
                .overlay(alignment: .trailing) {
                    Text(value)
                        .font(Font.custom("Okuda", size: 42))
                        .foregroundColor(.gray)
                        .padding(.leading)
                }
            Rectangle()
                .fill(.gray)
                .frame(maxWidth:.infinity)
                .overlay(alignment: .leading) {
                    Text(key)
                        .font(Font.custom("Okuda", size: 22))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .offset(x:0,y:3)
                        .foregroundColor(.black)
                        .background(Color.gray)
                }
                .frame(height:30)
        }
        .frame(maxWidth: .infinity, maxHeight: 30)
        .padding(0)
        .accessibilityIdentifier("KeyValueIndicator")
    }
}
