//
//  HueTrekApp.swift
//  HueTrek
//
//  Created by Louis Roehrs on 3/10/25.
//

import SwiftUI
import SwiftData

@main
struct HueTrekApp: App {
/*    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

*/

    @StateObject private var hueManager = HueManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(hueManager)
        }
    }
}
