
//
//  BridgeSelectorView.swift
//  HueTrek
//
//  Created by Louis Roehrs on 4/18/25.
//
import SwiftUI

struct BridgeSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var hueManager: HueManager

    
    var body: some View {
        NavigationView {
            VStack (spacing: 6) {
                HStack(spacing:6) {// Header
                    TopLeftRoundedRectangle(radius: 40)
                        .fill(Color(hex:0xF5ED00))
                    
                    Text( "BRIDGES")
                        .textCase(.uppercase)
                        .font(Font.custom("Okuda Bold", size: 50))
                        .kerning(1.1)
                        .padding(.bottom,2)
                        .foregroundColor(Color(hex:0xF5ED00))
                        .layoutPriority(1)
                    
                    
                    Rectangle(radius: 40)
                        .fill(Color(hex:0xFF9C00))
                        .frame(width:40, height:40)
                        .padding(0)
                        .overlay(
                            Image(systemName: "chevron.down")
                                .foregroundColor(Color.black)
                                .font(.system(size: 30))
                                .padding(0)
                        )
                        .onTapGesture {
                            hueManager.playSound(sound: "colorpickerslidedown")
                            presentationMode.wrappedValue.dismiss()
                        }
                    
                }
                .frame(maxHeight:40)
                VStack {
                    Text( "Press and hold name to rename or delete")
                        .textCase(.uppercase)
                        .font(Font.custom("Okuda Bold", size: 25))
                        .kerning(1.3)
                        .foregroundColor(Color(hex:0x6888FF))
                        .layoutPriority(1)
                        .padding()

                    List {
                        ForEach(hueManager.bridgeConfigurations) { config in
                            BridgeRowItem(config: config)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden) // Hide default list background
                    .background(Color.black)
                    .navigationBarTitleDisplayMode(.inline)
                }
                .overlay(
                    Rectangle()
                        .frame(width: 12)
                        .foregroundColor(Color(hex:0xFF9C00))
                        .padding(.bottom, -10),
                    alignment: .leading
                )

                HStack(spacing: 4){
                    BottomLeftRoundedRectangle(radius:hueManager.ui.footerHeight)
                        .fill(Color(hex:0xFF9C00))
                        .frame(width:50,height:hueManager.ui.footerHeight)
                    
                    Text(hueManager.currentBridgeConfig?.name ?? "BRIDGE")
                        .font(Font.custom("Okuda Bold", size: hueManager.ui.footerLabelFontSize))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.blue)
                        .padding(.bottom, 1)
                        .layoutPriority(1)
                    
                    Rectangle()
                        .fill(Color(hex:0xFF9C00))
                        .frame(maxHeight:hueManager.ui.footerHeight)
                        .overlay( alignment: .trailing) {
                            Text("ADD")
                                .font(Font.custom("Okuda Bold", size: hueManager.ui.footerButtonFontSize))
                                .textCase(.uppercase)
                                .foregroundColor(.black)
                                .padding(.bottom, -4)
                                .padding(.trailing, 1)
                        }
                        .onTapGesture {
                            hueManager.playSound(sound: "add_bridge")
                            hueManager.addBridgeTapped()
                            presentationMode.wrappedValue.dismiss()
                        }
                    
                    RightRoundedRectangle(radius: hueManager.ui.footerHeight/2)
                        .fill(Color(hex:0xFF9C00))
                        .frame(width: 40, height: hueManager.ui.footerHeight)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all)) // Set the NavigationView background
        }
        .preferredColorScheme(.dark)
    }

}

struct BridgeRowItem: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var hueManager: HueManager
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var editingBridgeId: UUID?
    @FocusState private var isFocused: Bool
    
    let config: BridgeConfiguration
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(hex:0x6888FF))
                .frame(maxHeight:40)
                .overlay(alignment: .leading){
                    
                    if isEditingName && editingBridgeId == config.id {
                        TextField("Bridge Name", text: $editedName, onCommit: {
                            if editingBridgeId == hueManager.currentBridgeConfig?.id {
                                hueManager.updateBridgeName(editedName)
                            }
                            isEditingName = false
                            editingBridgeId = nil
                        })
                        .textCase(.uppercase)
                        .font(Font.custom("Okuda", size: 24))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.blue)
                        .focused($isFocused)
                        .onAppear {
                            isFocused = true
                        }
                    } else {
                        Text(config.name)
                            .textCase(.uppercase)
                            .font(Font.custom("Okuda", size: 24))
                            .foregroundColor(.black)
                            .padding(.bottom, -10)
                            .padding(.leading, 8)
                            .layoutPriority(1)
                    }
                }
                .background(Color.black)
            
            if config.id == hueManager.currentBridgeConfig?.id {
                RightRoundedRectangle()
                    .fill(Color(hex:0x009900))
                    .frame(width:40,height:40)
                    .padding(0)
            } else {
                RightRoundedRectangle()
                    .fill(Color(.black))
                    .frame(width:40,height:40)
                    .padding(0)
            }
        }
        .padding(.leading, 20)
        .contextMenu {
            Button("Rename") {
                hueManager.playSound(sound: "rename")
                editingBridgeId = config.id
                editedName = config.name
                isEditingName = true
            }
            Button("Delete", role: .destructive) {
                hueManager.playSound(sound: "denybeep4")
                hueManager.removeBridge(withId: config.id)
            }
        }
        .onTapGesture {
            hueManager.playSound(sound: "colorpickerslidedown")
            hueManager.switchToBridge(withId: config.id)
            presentationMode.wrappedValue.dismiss()
        }
    }

}

#Preview {
    BridgeSelectorView()
        .environmentObject(HueManager.preview)
}


