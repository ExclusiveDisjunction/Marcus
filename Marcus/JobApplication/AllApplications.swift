//
//  AllApplications.swift
//  Marcus
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

public struct AllApplications : View {
    
    @QuerySelection<JobApplication>(sortDescriptors: [SortDescriptor(\JobApplication.internalAppliedOn)])
    private var applications;
    
    private let warning = SelectionWarningManifest();
    private let inspect = InspectionManifest<JobApplication>();
    private let delete = DeletingManifest<JobApplication>();
    
    @State private var showingFilter = false;
    @State private var showingStats = false;
    
    public var body: some View {
        Table(context: applications) {
            TableColumn("Position", value: \.position)
                .width(min: 100, ideal: 150)
            TableColumn("Company", value: \.company)
            TableColumn("Applied On") { app in
                Text(app.appliedOn.formatted(date: .numeric, time: .omitted))
            }
            TableColumn("Status", value: \.state)
            TableColumn("Location") { app in
                Text(app.location ?? "-")
            }
            TableColumn("Location Kind", value: \.locationKind)
            TableColumn("Position Kind", value: \.kind)
        }.padding()
            .withElementDeleting(manifest: delete)
            .withElementIE(manifest: inspect) { app in
                app.position = "";
                app.company = "";
                app.appliedOn = .now;
                app.state = .applied;
                app.location = nil;
                app.locationKind = .onSite;
                app.kind = .fullTime;
                app.notes = "";
                app.website = nil;
            }
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingStats = true;
                    } label: {
                        Label("Show Statistics", systemImage: "chart.bar")
                    }
                }
                
                ElementAddButton(inspect: inspect, placement: .primaryAction)
                ElementInspectButton(context: applications, inspect: inspect, warning: warning, placement: .primaryAction)
                ElementEditButton(context: applications, inspect: inspect, warning: warning, placement: .primaryAction)
                ElementDeleteButton(context: applications, delete: delete, warning: warning, placement: .primaryAction)
            }
            .navigationTitle("Marcus")
            .sheet(isPresented: $showingStats) {
                JobStatsViewer()
            }
    }
}

#Preview(traits: .sampleData) {
    AllApplications()
}
