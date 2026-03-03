//
//  ContentView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationStack {
            AllApplications()
        }
    }

}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    ContentView()
}
