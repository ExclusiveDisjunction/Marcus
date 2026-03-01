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

public struct FilterSubsection<C, T> : View
where C: AnyObject,
      T: Hashable & Identifiable & Displayable & CaseIterable,
      T.AllCases: RandomAccessCollection {
    
    public init(_ name: LocalizedStringKey, source: C, path: WritableKeyPath<C, Set<T>>) {
        self.name = name;
        self.source = source;
        self.path = path;
    }
    
    let name: LocalizedStringKey;
    let source: C;
    let path: WritableKeyPath<C, Set<T>>;
    
    func bind(val: T) -> Binding<Bool> {
        Binding(
            get: {
                source[keyPath: path].contains(val)
            },
            set: { [source] newValue in
                var source = source;
                
                if newValue {
                    source[keyPath: path].insert(val)
                }
                else {
                    source[keyPath: path].remove(val)
                }
            }
        )
    }
    
    public var body: some View {
        Section {
            ForEach(T.allCases) { value in
                Toggle(value.display, isOn: bind(val: value))
            }
        } header: {
            HStack {
                Text(name)
                
                Divider()
                
                Button("Select All") { [source] in
                    var source = source;
                    
                    source[keyPath: path] = Set(T.allCases)
                }.buttonStyle(.borderless)
                Button("Deselect All") { [source] in
                    var source = source;
                    
                    source[keyPath: path] = Set()
                }.buttonStyle(.borderless)
            }
        }
    }
}

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
    
    @Published public var queryString: String;
    @Published public var uiQueryString: String;
    private var cancel: (any Cancellable)?;
    
    private var predicate: NSPredicate? = nil;
    private var lastHash: Int = 0;
    
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

public enum DatesFilterRange : Int, Hashable, Equatable, Identifiable, CaseIterable {
    case anyDate
    case before
    case after
    case between
    
    public var id: Self { self }
}

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
    
    public var states: Set<JobApplicationState>;
    public var kinds: Set<JobKind>;
    public var locations: Set<JobLocation>;
    public var filterRange: DatesFilterRange = .anyDate;
    public var before: Date = .now;
    public var after: Date = .now;
    
    @ObservationIgnored private var predicate: NSPredicate?;
    @ObservationIgnored private var lastHash: Int;
    
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

    
    public func reset() {
        states = Set(JobApplicationState.allCases)
        kinds = Set(JobKind.allCases)
        locations = Set(JobLocation.allCases)
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

public struct JobsFilter : View {
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

#Preview(traits: .sampleData) {
    @Previewable let state = ApplicationsFilterState()
    
    JobsFilter(state)
}
