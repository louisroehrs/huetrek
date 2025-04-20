
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
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var editingBridgeId: UUID?
    @FocusState private var isFocused: Bool
    
    func addBridgeTapped() {
        hueManager.discoverBridge()
        hueManager.playSound(sound: "colorpickerslidedown")
        hueManager.isAddingNewBridge = true
    }
    
    var body: some View {
        NavigationView {
            VStack (spacing: 6) {
                HStack(spacing:6) {// Header
                    TopLeftRoundedRectangle(radius: 40)
                        .fill(Color(hex:0xF5ED00))
                        .layoutPriority(1)
                        .overlay(alignment: .trailing) {
                            Text( "Press and hold name to rename or delete")
                                .textCase(.uppercase)
                                .font(Font.custom("Okuda Bold", size: 25))
                                .padding(.bottom,-10)
                                .padding(.trailing, 3)
                                .foregroundColor(Color.black)
                                .layoutPriority(1)
                                .kerning(1.3)
                        }
                    
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
                List {
                    ForEach(hueManager.bridgeConfigurations) { config in
                        HStack(spacing:8) {

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
                                        .focused($isFocused)  // Add focus binding
                                        .onAppear {
                                            isFocused = true  // Automatically focus when TextField appears
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
                        .background(Color.black)
                        .onTapGesture {
                            hueManager.playSound(sound: "colorpickerslidedown")
                            hueManager.switchToBridge(withId: config.id)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.leading, 20)
                        .contextMenu {
                            Button("Rename") {
                                editingBridgeId = config.id
                                editedName = config.name
                                isEditingName = true
                            }
                            Button("Delete", role: .destructive) {
                                hueManager.removeBridge(withId: config.id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden) // Hide default list background
                .background(Color.black) // Set the list background to black
                .navigationBarTitleDisplayMode(.inline)
                .overlay(
                    // Left border
                    Rectangle()
                        .frame(width: 12)
                        .foregroundColor(Color(hex:0xFF9C00))
                        .padding(.bottom, -10),
                    alignment: .leading
                )

                HStack(spacing: 4){
                    BottomLeftRoundedRectangle(radius:30)
                        .fill(Color(hex:0xFF9C00))
                        .frame(width:50,height:30)

                    Text(hueManager.currentBridgeConfig?.name ?? "BRIDGE")
                        .font(Font.custom("Okuda Bold", size: 40))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.blue)
                        .padding(.bottom, 1)
                        .layoutPriority(1)
                    
                    Rectangle()
                        .fill(Color(hex:0xFF9C00))
                        .frame(maxHeight:30)
                        .overlay( alignment: .trailing) {
                            Text("ADD")
                                .font(Font.custom("Okuda Bold", size: 30))
                                .textCase(.uppercase)
                                .foregroundColor(.black)
                                .padding(.bottom, -4)
                                .padding(.trailing, 1)
                                
                        }
                    RightRoundedRectangle(radius: 15)
                        .fill(Color(hex:0xFF9C00))
                        .frame(width:40,height:30)

                }
                .background(Color.black)
                .listStyle(.plain)
                .onTapGesture {
                    addBridgeTapped()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .listStyle(.plain)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Set the NavigationView background
        .preferredColorScheme(.dark) // Optional: ensure dark mode for the sheet
    }
}


#Preview {
    BridgeSelectorView()
        .environmentObject(HueManager.preview)
}


