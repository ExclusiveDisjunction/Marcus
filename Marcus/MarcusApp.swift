//
//  MarcusApp.swift
//  Marcus
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

@main
struct MarcusApp: App {
    let persistenceController = DataStack.shared.currentContainer;

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
