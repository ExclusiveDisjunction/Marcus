//
//  JobApplicationEdit.swift
//  Marcus
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI

public struct JobApplicationEdit : View {
    public init(_ source: JobApplication) {
        self.source = source;
    }
    
    private let source: JobApplication;
    
    public var body: some View {
        
    }
}

extension JobApplication : EditableElement {
    public typealias EditView = JobApplicationEdit;
    
    @MainActor
    public func makeEditView() -> JobApplicationEdit {
        JobApplicationEdit(self)
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
