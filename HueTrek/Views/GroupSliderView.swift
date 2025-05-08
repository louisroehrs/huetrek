//
//  GroupSliderView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/20/25.
//


import SwiftUI
import Combine

struct GroupSliderView: View {
    @EnvironmentObject private var hueManager: HueManager

    @Binding var sliderValue: Double
    var group: LightGroup
    @State private var lastSentValue: Double = 0
    @State private var isDragging = false
    @State private var cancellable: AnyCancellable?
    
    var body: some View {
        VStack {
            Slider(value: $sliderValue, in: 1...254, onEditingChanged: { editing in
                isDragging = editing
                if !editing {
                    // Send the final value when user stops dragging
                    sendUpdate(sliderValue)
                }
            })
            .padding()
        }
        .onChange(of: sliderValue) { 
            if isDragging {
                // Throttle updates to once per second
                throttledUpdate(value: sliderValue)
            }
        }
    }

    func throttledUpdate(value: Double) {
        // Cancel any pending scheduled update
        cancellable?.cancel()

        // Schedule a new update after 1 second
        cancellable = Just(value)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .sink { val in
                if isDragging {
                    sendUpdate(val)
                    lastSentValue = val
                }
            }
    }

    func sendUpdate(_ value: Double) {
        let rounded = Int(value)
        guard rounded != Int(lastSentValue) else { return }
        
        hueManager.setBrightness(rounded, for: group)
        print("Sending throttled update \(rounded)")

    }

    func sendFinalUpdate() {
        print("This is FINAL:")
        let rounded = Int(sliderValue)
        if rounded != Int(lastSentValue) {
            sendUpdate(sliderValue)
        }
    }
}
