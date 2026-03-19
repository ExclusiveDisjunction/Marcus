//
//  JobApplicationInspect.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import ExDisj

/// A view that allows for the editing of a ``JobApplication``
public struct JobApplicationEdit : View {
    @ObservedObject public var source: JobApplication;
    
    @State private var hasUrl: Bool = false;
    @State private var rawUrl: String = "";
    @State private var urlError = false;
    
    public var body: some View {
        Form {
            Section {
                TextField("Position", text: $source.position)
                TextField("Company", text: $source.company)
                    .autocorrectionDisabled()
            }
            
            Section {
                DatePicker("Applied On", selection: $source.appliedOn, displayedComponents: [.date, .hourAndMinute])
                
                EnumPicker("Status", value: $source.state)
                    .onChange(of: source.state) { _, _ in
                        source.lastStatusUpdated = .now;
                    }
            }
            
            Section {
                EnumPicker("Position Kind", value: $source.kind)
                
                TextField("Location", text: $source.location)
                    .autocorrectionDisabled()
                EnumPicker("Job Kind", value: $source.locationKind)
                
            }
            
            Section {
                Toggle("Has Website?", isOn: $hasUrl)
                
                TextField("Website", text: $rawUrl)
                    .autocorrectionDisabled()
                    .disabled(!hasUrl)
                    .opacity(hasUrl ? 1.0 : 0.5)
                    .border(hasUrl ? Color.red : Color.clear)
                    .onChange(of: rawUrl) { _, raw in
                        guard let url = URL(string: raw) else {
                            urlError = true
                            return;
                        }
                        
                        urlError = false;
                        source.website = url;
                    }
                    .onChange(of: hasUrl) { _, hasUrl in
                        if !hasUrl {
                            source.website = nil;
                        }
                    }
                
                TextField("Notes", text: $source.notes)
            }
        }
    }
}

extension JobApplication : EditableElement {
    @MainActor
    public func makeEditView() -> JobApplicationEdit {
        JobApplicationEdit(source: self)
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<JobApplication>(sortDescriptors: [])
    var apps: FetchedResults<JobApplication>;
    
    @Previewable @Environment(\.dataStack) var dataStack;
    
    ElementEditor(using: dataStack, from: apps.first!)
}
