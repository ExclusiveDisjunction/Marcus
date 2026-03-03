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
    public init(_ source: JobApplication) {
        self._source = .init(wrappedValue: source);
    }
    
    @State private var hasUrl: Bool = false;
    @State private var rawUrl: String = "";
    @State private var urlError = false;
    
    @ObservedObject private var source: JobApplication;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        ScrollView {
            Grid {
                GridRow {
                    Text("Position:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Position", text: $source.position)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Company:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Company", text: $source.company)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Applied On:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        DatePicker("", selection: $source.appliedOn, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                        
                        Spacer()
                    }
                }
                
                GridRow {
                    Text("Status:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    EnumPicker(value: $source.state)
                }
                
                GridRow {
                    Text("Position Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    EnumPicker(value: $source.kind)
                }
                
                GridRow {
                    Text("Location:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Location", text: $source.location)
                        .textFieldStyle(.roundedBorder)
                }
                
                GridRow {
                    Text("Job Kind:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    EnumPicker(value: $source.locationKind)
                }
                
                GridRow {
                    Text("Has Website?")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    HStack {
                        Toggle("", isOn: $hasUrl)
                            .labelsHidden()
                        
                        Spacer()
                    }
                }
                
                if hasUrl {
                    GridRow {
                        Text("Website URL:")
                            .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                        
                        TextField("Location", text: $rawUrl)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: rawUrl) { _, raw in
                                guard let url = URL(string: raw) else {
                                    urlError = true
                                    return;
                                }
                                
                                urlError = false;
                                source.website = url;
                            }
                            .onChange(of: hasUrl) { _, hasUrl in
                                if hasUrl {
                                    guard let url = URL(string: rawUrl) else {
                                        urlError = true
                                        return;
                                    }
                                    
                                    source.website = url;
                                }
                                else {
                                    source.website = nil;
                                }
                            }
                    }
                    
                    if urlError {
                        GridRow {
                            Text("")
                            
                            HStack {
                                Text("The URL provided is not valid")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                }
                
                GridRow {
                    Text("Notes:")
                        .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                    
                    TextField("Notes", text: $source.notes)
                        .textFieldStyle(.roundedBorder)
                }
            }.padding()
        }
    }
}

extension JobApplication : EditableElement {
    @MainActor
    public func makeEditView() -> JobApplicationEdit {
        JobApplicationEdit(self)
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<JobApplication>(sortDescriptors: [])
    var apps: FetchedResults<JobApplication>;
    
    ElementEditor(using: DataStack.shared.debugContainer, from: apps.first!)
}
