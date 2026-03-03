//
//  JobApplicationEdit.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import ExDisj

/// A view that allows for the inspection of a ``JobApplication``
public struct JobApplicationInspect : View {
    public init(_ source: JobApplication) {
        self.source = source;
    }
    
    private let source: JobApplication;
    
#if os(macOS)
    private let minWidth: CGFloat = 80;
    private let maxWidth: CGFloat = 90;
#else
    private let minWidth: CGFloat = 110;
    private let maxWidth: CGFloat = 120;
#endif
    
    public var body: some View {
        Grid {
            GridRow {
                Text("Position:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(verbatim: source.position)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Company:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(verbatim: source.company)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Applied On:").frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(source.appliedOn.formatted(date: .abbreviated, time: .shortened))
                    
                    Spacer()
                }
            }
            
            GridRow {
                Text("Status:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DisplayableVisualizer(value: source.state)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Position Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DisplayableVisualizer(value: source.kind)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Location:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(verbatim: source.location)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Job Kind:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    DisplayableVisualizer(value: source.locationKind)
                    Spacer()
                }
            }
            
            GridRow {
                Text("Website URL:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(verbatim: source.website?.absoluteString ?? "-")
                    Spacer()
                }
            }
            
            GridRow {
                Text("Notes:")
                    .frame(minWidth: minWidth, maxWidth: maxWidth, alignment: .trailing)
                
                HStack {
                    Text(verbatim: source.notes)
                    Spacer()
                }
            }
        }
    }
}

extension JobApplication : InspectableElement {
    @MainActor
    public func makeInspectView() -> JobApplicationInspect {
        JobApplicationInspect(self)
    }
}
extension JobApplication : TypeTitled {
    public static var typeDisplay: TypeTitleStrings {
        return TypeTitleStrings(
            singular: "Job Application",
            plural: "Job Applications",
            inspect: "Inspect Job Application",
            edit: "Edit Job Application",
            add: "Add Job Application"
        )
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable @FetchRequest<JobApplication>(sortDescriptors: [])
    var apps: FetchedResults<JobApplication>;
    
    ElementInspector(data: apps.first!)
}
