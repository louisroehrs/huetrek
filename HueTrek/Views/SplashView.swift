//
//  SplashView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/28/25.
//
import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    @State private var offsetY: Double = -300

    var body: some View {
        VStack {
            Image("HueTrek") // your logo asset
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 200)
                .scaleEffect(scale)
                .opacity(opacity)
                .offset(y:offsetY)
                .onAppear {
                    withAnimation(.easeOut(duration:1)) {
                        self.offsetY = 0
                        self.scale = 1.1
                        self.opacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        withAnimation(.easeIn(duration: 0.7)) {
                            self.offsetY = -50 // bounce back up slightly
                            self.scale = 1.2
                            self.opacity = 1.0
                        }
                    }
                }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
