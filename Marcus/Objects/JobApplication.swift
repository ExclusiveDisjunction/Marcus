//
//  JobApplication.swift
//  Marcus
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData

public enum JobApplicationState : Int16, Equatable, Hashable, Codable, Sendable {
    case applied = 0
    case underReview = 1
    case inInterview = 2
    case rejected = 3
    case accepted = 4
}
extension JobApplicationState : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .applied: "Applied"
            case .underReview: "Under Review"
            case .inInterview: "In Interview"
            case .rejected: "Rejected"
            case .accepted: "Accepted"
        }
    }
}

public enum JobLocation : Int16, Equatable, Hashable, Codable, Sendable {
    case onSite = 0
    case hybrid = 1
    case remote = 2
}
extension JobLocation : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .onSite: "On-Site"
            case .hybrid: "Hybrid"
            case .remote: "Remote"
        }
    }
}

public enum JobKind : Int16, Equatable, Hashable, Codable, Sendable {
    case fullTime = 0
    case partTime = 1
    case seasonal = 2
    case contractor = 3
}
extension JobKind : Displayable {
    public var display: LocalizedStringKey {
        switch self {
            case .fullTime: "Full Time"
            case .partTime: "Part Time"
            case .seasonal: "Seasonal"
            case .contractor: "Contractor/Freelance"
        }
    }
}

public extension JobApplication {
    var position: String {
        get { self.internalPosition ?? String() }
        set { self.internalPosition = newValue }
    }
    var company: String {
        get { self.internalCompany ?? String() }
        set { self.internalCompany = newValue }
    }
    var appliedOn: Date {
        get { self.internalAppliedOn ?? .distantPast }
        set { self.internalAppliedOn = newValue }
    }
    var state: JobApplicationState {
        get { JobApplicationState(rawValue: self.internalState) ?? .applied }
        set { self.internalState = newValue.rawValue }
    }
    var kind: JobKind {
        get { JobKind(rawValue: self.internalKind) ?? .fullTime }
        set { self.internalKind = newValue.rawValue }
    }
    var locationKind: JobLocation {
        get { JobLocation(rawValue: self.internalLocationKind) ?? .onSite }
        set { self.internalLocationKind = newValue.rawValue }
    }
    var notes: String {
        get { self.internalNotes ?? String() }
        set { self.internalNotes = newValue }
    }
}
