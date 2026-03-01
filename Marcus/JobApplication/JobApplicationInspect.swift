//
//  JobApplicationInspect.swift
//  Marcus
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI

public struct JobApplicationInspect : View {
    public init(_ source: JobApplication) {
        self.source = source;
    }
    
    private let source: JobApplication;
    
    public var body: some View {
        
    }
}

extension JobApplication : InspectableElement {
    @MainActor
    public func makeInspectView() -> JobApplicationInspect {
        JobApplicationInspect(self)
    }
}
