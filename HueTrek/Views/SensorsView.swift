//
//  SensorsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct SensorsView: View {
    @EnvironmentObject private var hueManager: HueManager
    
    var body: some View {
        
        VStack {
            List {
                ForEach(hueManager.sensors) { sensor in
                    SensorRowView(sensor: sensor)
                        .listRowBackground(Color.black)
                        .background(Color.black)
                }
            }
            .listStyle(.plain)
            .padding(.leading, 12)
            .scrollContentBackground(.hidden)
            .onAppear {
                hueManager.fetchSensors()
            }
        }
        .background(Color(hex: 0xCCE0F7))
    }
}



struct SensorRowView: View {
    let sensor: HueManager.Sensor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.cyan)
                .frame(height:10)
                .padding(0)
            HStack {
                VStack(alignment: .leading) {
                    Text(sensor.name)
                        .font(Font.custom("Okuda", size: 24))
                        .foregroundColor(.blue)
                    
                    Text(sensor.type)
                        .font(Font.custom("Okuda", size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Battery indicator
                HStack(spacing: 2) {
                    Image(systemName: "battery.100")
                        .foregroundColor(sensor.config.battery > 20 ? .green : .red)
                    Text("\(sensor.config.battery)%")
                        .font(Font.custom("Okuda", size: 14))
                        .foregroundColor(.gray)
                }
                
                // Connection status
                Circle()
                    .fill(sensor.config.reachable ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
            }
            
            if let lastUpdated = sensor.state.lastupdated {
                Text("Last Updated: \(lastUpdated)")
                    .font(Font.custom("Okuda", size: 14))
                    .foregroundColor(.gray)
            }
            
            if let rotaryEvent = sensor.state.rotaryevent {
                Text("Rotary Event: \(rotaryEvent)")
                    .font(Font.custom("Okuda", size: 14))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(10)
    }
}

