//
//  ValidationFailure.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/29/25.
//

import SwiftUI

/// A failure to validate a value out of a snapshot/element.
public enum ValidationFailure: Int, Identifiable, Sendable, Error {
    /// A uniqueness check failed over a set of identifiers.
    case unique
    /// A field was empty
    case empty
    /// A field was negative
    case negativeAmount
    /// A field is too large
    case tooLargeAmount
    /// A field is too small
    case tooSmallAmount
    /// A field has invalid input
    case invalidInput
    ///Happens when there is an internal expection that failed
    case internalError
    
    public var id: Self { self }
    
    public var localizedDescription: String {
        switch self {
            case .unique:         "The current element is not unique."
            case .empty:          "Please ensure all fields are filled in."
            case .negativeAmount: "Please ensure all amount values are positive."
            case .tooLargeAmount: "Please ensure all fields are not too large. (Ex: Percents greater than 100%)"
            case .tooSmallAmount: "Please ensure all fields are not too small."
            case .invalidInput:   "One or more fields has invalid input."
            case .internalError:  "Internal error failure"
        }
    }
}

extension ValidationFailure : Displayable {
     public var display: LocalizedStringKey {
        switch self {
            case .unique:         "The current element is not unique."
            case .empty:          "Please ensure all fields are filled in."
            case .negativeAmount: "Please ensure all amount values are positive."
            case .tooLargeAmount: "Please ensure all fields are not too large. (Ex: Percents greater than 100%)"
            case .tooSmallAmount: "Please ensure all fields are not too small."
            case .invalidInput:   "One or more fields has invalid input."
            case .internalError:
                fallthrough
            default:
                "internalError"
                
        }
    }
}
extension ValidationFailure : WarningBasis {
    public var message: LocalizedStringKey {
        self.display
    }
}
