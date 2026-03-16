//
//  ContentView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import ExDisj
import os

struct ContentView: View {
    @Environment(\.dataStack) private var dataStack;
    @Environment(\.statusReviewer) private var statusReviewer;
    @Environment(\.logger) private var logger;
    @State private var currentPage: Pages? = .jobs;
    @FocusState private var isFocused: Bool;
    
    enum Pages: Identifiable, Sendable, Equatable, Hashable, Displayable, CaseIterable {
        case jobs
        case followUps
        
        var display: LocalizedStringKey {
            switch self {
                case .jobs: "Job Applications"
                case .followUps: "Follow-Up Reminders"
            }
        }
        var id: Self {
            self
        }
    }
    
    @ViewBuilder
    private var currentPageView: some View {
        switch (currentPage ?? .jobs) {
            case .jobs: AllApplications()
            case .followUps: StatusReviewHomepage()
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $currentPage) {
                ForEach(Pages.allCases) { page in
                    Text(page.display)
                        .tag(page)
                }
            }
        } detail: {
            currentPageView
                .focusedSceneValue(\.statusReviewer, statusReviewer)
        }.navigationSplitViewColumnWidth(120)
            .navigationSplitViewStyle(.prominentDetail)
            .navigationTitle(currentPage?.display ?? "Ghosted")
            .withStatusReviewer(statusReviewer)
            .focusable()
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
    }

}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    ContentView()
}
