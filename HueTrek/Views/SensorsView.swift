//
//  SensorsView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/13/25.
//

import SwiftUI

struct SensorsView: View {
    @EnvironmentObject private var hueManager: HueManager
    let borderColor: Color
    
    var body: some View {
        
        VStack {
            if let error = hueManager.error {
                NoBridgeFoundView(repeatAction: hueManager.fetchSensors)
            } else {
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
                .refreshable {
                    hueManager.fetchGroups()
                }
            }
        }
        .background(Color(hex: 0x000000))
        .overlay(
            Rectangle()
                .frame(width: 12)
                .foregroundColor(borderColor)
                .padding(.vertical, 0),
            alignment: .leading
        )
    }
}

struct SensorRowView: View {
    let sensor: Sensor
    
    func batteryToSFSymbol(_ batteryPercent: Int) -> String {
        if batteryPercent>90 { return "battery.100" }
        if batteryPercent>74 { return "battery.75"  }
        if batteryPercent>49 { return "battery.50"  }
        if batteryPercent>24 { return "battery.25"  }
        if batteryPercent>10 { return "battery.25"  }
        return "battery.0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing:0) {
            Rectangle()
                .fill(Color.cyan)
                .frame(height:15)
                .padding(0)
                .cornerRadius(0)
            VStack(alignment: .leading) {
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(sensor.name)
                            .font(Font.custom("Okuda", size: 28))
                            .foregroundColor(.blue)
                        
                        Text(sensor.type)
                            .font(Font.custom("Okuda", size: 24))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Battery indicator
                    HStack(spacing: 2) {
                        Image(systemName: batteryToSFSymbol(sensor.config.battery))
                            .foregroundColor(sensor.config.battery > 20 ? .green : .red)
                        Text("\(sensor.config.battery)%")
                            .font(Font.custom("Okuda", size: 20))
                            .foregroundColor(.gray)
                    }
                    
                    // Connection status
                    Circle()
                        .fill(sensor.config.reachable ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                }
                .padding(.top, 4)
             
                
                if let rotaryEvent = sensor.state.rotaryevent {
                    Text("Rotary Event: \(rotaryEvent)")
                        .font(Font.custom("Okuda", size: 20))
                        .foregroundColor(.blue)
                }

                if let lastUpdated = sensor.state.lastupdated {
                    Text("Last Updated: \(lastUpdated)")
                        .font(Font.custom("Okuda", size: 20))
                        .foregroundColor(.blue)
                }
                
                Text("Manufacturer:  \(sensor.manufacturername)")
                    .font(Font.custom("Okuda", size: 20))
                    .foregroundColor(.gray)
                
                Text("Product Name: \(sensor.productname)")
                    .font(Font.custom("Okuda", size: 20))
                    .foregroundStyle(.gray)
                
            }
            .padding(.leading, 16)
            .padding(.bottom, 20)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.cyan)
                    .frame(width: 8)
                    .padding(.top, 0)
            }
        }
        .padding(0)
        .background(Color.black)
        .cornerRadius(20)
    }
}

