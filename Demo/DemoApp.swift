//
//  DemoApp.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//

import SwiftUI
import SwiftData

@main
struct DemoApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([NewsArticleModel.self])
        let config = ModelConfiguration(schema: schema)
        container = try! ModelContainer(for: schema, configurations: config)
        
        _ = NetworkMonitor.shared
        _ = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
