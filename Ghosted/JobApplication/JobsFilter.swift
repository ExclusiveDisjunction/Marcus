//
//  JobsFilter.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/1/26.
//

import SwiftUI
import CoreData
import Combine
import Observation
import ExDisj

/// A View-Model state that allows for querying via a search string.
///
/// This VM stores two values: ``ApplicationsSearchState/queryString`` and ``ApplicationsSearchState/uiQueryString``. The UI variant is designed to be bound directly to UI `searchable` instances. It is set up so that after 400 ms, the ``ApplicationsSearchState/queryString`` will be updated.
/// The predicate produced will look for positions or companies containg the query string.
@MainActor
public class ApplicationsSearchState : ObservableObject, Hashable, Equatable {
    public init() {
        self.queryString = ""
        self.uiQueryString = "";
        self.cancel = nil; //Temporary
        
        self.cancel = $uiQueryString
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.queryString = value.trimmingCharacters(in: .whitespacesAndNewlines)
            };
    }
    
    @MainActor
    deinit {
        cancel?.cancel()
    }
    
    /// The current query string.
    @Published public var queryString: String;
    /// The UI facing query string. This will debounce update to ``ApplicationsSearchState/queryString``.
    @Published public var uiQueryString: String;
    /// A cancelation token that will be called when the class deinits.
    private var cancel: (any Cancellable)?;
    
    /// The cached predicate.
    private var predicate: NSPredicate? = nil;
    /// The last hash value to compare to determine if the predicate needs to be updated.
    private var lastHash: Int = 0;
    
    /// Creates a predicate around the ``ApplicationsSearchState/queryString``.
    ///
    /// If the class has not changed between the last call to ``computePredicate()``, the internally cached predicate will be returned. Otherwise, a new predicate will be made, and cached.
    public func computePredicate() -> NSPredicate? {
        if lastHash == self.hashValue {
            return predicate;
        }
    
        if queryString.isEmpty {
            self.predicate = nil;
        }
        else {
            self.predicate = NSPredicate(format: "internalPosition CONTAINS[cd] %@ OR internalCompany CONTAINS[cd] %@", queryString, queryString);
        }
        
        lastHash = self.hashValue;
        return self.predicate;
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(queryString)
    }
    public static func ==(lhs: ApplicationsSearchState, rhs: ApplicationsSearchState) -> Bool {
        lhs.queryString == rhs.queryString
    }
}

/// A filter state for selecting date ranges.
public enum DatesFilterRange : Int, Hashable, Equatable, Identifiable, CaseIterable {
    /// Disables the filter, i.e. allows all dates.
    case anyDate
    /// Accepts any date before a specified date.
    case before
    /// Accepts any date after a specified date.
    case after
    /// Accepts any date between two specified dates.
    case between
    
    public var id: Self { self }
}

/// A View-Model state that allows for filtering of job application instances.
@MainActor
@Observable
public class ApplicationsFilterState : Hashable, Equatable {
    public init() {
        states = Set(JobApplicationState.allCases)
        kinds = Set(JobKind.allCases)
        locations = Set(JobLocation.allCases)
        self.predicate = nil;
        self.lastHash = 0;
    }
    
    /// All allowed job application states.
    public var states: Set<JobApplicationState>;
    /// All allowed job kinds.
    public var kinds: Set<JobKind>;
    /// All allowed job location kinds.
    public var locations: Set<JobLocation>;
    /// The current filter state range
    public var filterRange: DatesFilterRange = .anyDate;
    /// The begin date (used for ``DatesFilterRange/before`` and ``DatesFilterRange/between``)
    public var before: Date = .now;
    /// The end date (used for ``DatesFilterRange/after`` and ``DatesFilterRange/between``)
    public var after: Date = .now;
    
    /// The cached predicate.
    @ObservationIgnored private var predicate: NSPredicate?;
    /// The last hash value to compare to determine if the predicate needs to be updated.
    @ObservationIgnored private var lastHash: Int;
    
    /// Creates a predicate around the ``ApplicationsFilterState`` values.
    ///
    /// If the class has not changed between the last call to ``preparePredicate()()``, the internally cached predicate will be returned. Otherwise, a new predicate will be made, and cached.
    public func preparePredicate() -> NSPredicate {
        if let predicate = self.predicate, self.hashValue == lastHash {
            return predicate;
        }
        
        var parts: [NSPredicate] = [];
        parts.append(
            NSPredicate(format: "internalState in %@", states.map { $0.rawValue })
        )
        parts.append(
            NSPredicate(format: "internalKind in %@", kinds.map { $0.rawValue })
        )
        parts.append(
            NSPredicate(format: "internalLocationKind in %@", locations.map { $0.rawValue })
        )
        
        switch self.filterRange {
            case .anyDate: ()
            case .before:
                parts.append(
                    NSPredicate(format: "internalAppliedOn < %@", before as NSDate)
                )
            case .after:
                parts.append(
                    NSPredicate(format: "internalAppliedOn > %@", after as NSDate)
                )
            case .between:
                parts.append(
                    NSPredicate(format: "internalAppliedOn BETWEEN %@", [before as NSDate, after as NSDate])
                )
        }
        
        let result = NSCompoundPredicate(andPredicateWithSubpredicates: parts);
        predicate = result;
        lastHash = self.hashValue;
        
        return result;
    }

    
    /// Resets the internal state to the default
    public func reset() {
        states = Set(JobApplicationState.allCases)
        kinds = Set(JobKind.allCases)
        locations = Set(JobLocation.allCases)
        filterRange = .anyDate
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(states)
        hasher.combine(kinds)
        hasher.combine(locations)
        hasher.combine(filterRange)
        hasher.combine(before)
        hasher.combine(after)
    }
    public static func ==(lhs: ApplicationsFilterState, rhs: ApplicationsFilterState) -> Bool {
        lhs.states == rhs.states && lhs.kinds == rhs.kinds && lhs.locations == rhs.locations && lhs.filterRange == rhs.filterRange && lhs.before == rhs.before && lhs.after == rhs.after
    }
}

/// A view that allows for the modification of a ``ApplicationsFilterState``.
public struct JobsFilter : View {
    /// Binds the view to a specific filter state.
    public init(_ state: ApplicationsFilterState) {
        self.state = state;
    }
    
    @Bindable private var state: ApplicationsFilterState;
    @Environment(\.dismiss) private var dismiss;
    
    public var body: some View {
        VStack {
            HStack {
                Text("Filters")
                    .font(.title2)
                
                Spacer()
                
                Button("Reset All") {
                    state.reset()
                }.buttonStyle(.borderless)
            }
            
            List {
                Section("Applied On") {
#if os(macOS)
                    Picker("", selection: $state.filterRange) {
                        Text("Any Date").tag(DatesFilterRange.anyDate)
                        
                        HStack {
                            Text("Before")
                            DatePicker("Begin", selection: $state.before, displayedComponents: [.date])
                                .labelsHidden()
                        }.tag(DatesFilterRange.before)
                        
                        HStack {
                            Text("After")
                            DatePicker("End", selection: $state.after, displayedComponents: [.date])
                                .labelsHidden()
                        }.tag(DatesFilterRange.after)
                        
                        HStack {
                            Text("Between")
                            DatePicker("Begin", selection: $state.before, displayedComponents: [.date])
                                .labelsHidden()
                            Text("and")
                            DatePicker("End", selection: $state.after, displayedComponents: [.date])
                                .labelsHidden()
                        }.tag(DatesFilterRange.between)
                    }.labelsHidden()
                        .pickerStyle(.radioGroup)
#else
                    Picker("", selection: $state.filterRange) {
                        Text("Any Date").tag(DatesFilterRange.anyDate)
                        Text("Before").tag(DatesFilterRange.before)
                        Text("After").tag(DatesFilterRange.after)
                        Text("Between").tag(DatesFilterRange.between)
                    }.labelsHidden()
                        .pickerStyle(.segmented)
                
                    if state.filterRange == .before || state.filterRange == .between {
                        DatePicker("Begin", selection: $state.before, displayedComponents: [.date])
                    }
                    
                    if state.filterRange == .after || state.filterRange == .between {
                        DatePicker("End", selection: $state.after, displayedComponents: [.date])
                    }
#endif
                }.onChange(of: state.before) { _, value in
                    if value > state.after {
                        state.before = state.after
                    }
                }.onChange(of: state.after) { _, value in
                    if value < state.before {
                        state.after = state.before
                    }
                }
                
                FilterSubsection("States", source: state, path: \.states)
                FilterSubsection("Job Kinds", source: state, path: \.kinds)
                FilterSubsection("Location Kinds", source: state, path: \.locations)
            }.frame(minHeight: 200)
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Ok") {
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

@available(macOS 15, iOS 18, *)
#Preview(traits: .sampleData) {
    @Previewable let state = ApplicationsFilterState()
    
    JobsFilter(state)
}
