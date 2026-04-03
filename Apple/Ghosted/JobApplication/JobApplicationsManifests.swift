//
//  JobApplicationsManifests.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/14/26.
//

import SwiftUI
import ExDisj

@Observable
public class JobApplicationsManifests {
    public init() {
        
    }
    
    public var warning = SelectionWarningManifest();
    public var inspect = InspectionManifest<JobApplication>();
    public var delete = DeletingManifest<JobApplication>();
}

fileprivate struct ManifestsKey : FocusedValueKey {
    typealias Value = JobApplicationsManifests
}
public extension FocusedValues {
    var jobApplicationManifests : JobApplicationsManifests? {
        get { self[ManifestsKey.self] }
        set { self[ManifestsKey.self] = newValue }
    }
}
