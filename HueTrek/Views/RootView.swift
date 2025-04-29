//
//  RootView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/28/25.
//
import SwiftUI

struct RootView: View {
    @State private var isActive = false

    var body: some View {
        NavigationStack { // Always have NavigationStack alive
            ZStack {
                if isActive {
                    ContentView()
                } else {
                    SplashView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    isActive = true
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    RootView()
}
