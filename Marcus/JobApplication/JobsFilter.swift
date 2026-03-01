//
//  JobsFilter.swift
//  Marcus
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
    }
    
    @Published public var queryString: String;
    @Published public var uiQueryString: String;
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(queryString)
        hasher.combine(uiQueryString)
    }
    public static func ==(lhs: ApplicationsSearchState, rhs: ApplicationsSearchState) -> Bool {
        lhs.queryString == rhs.queryString && lhs.uiQueryString == rhs.uiQueryString
    }
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
    }
    public static func ==(lhs: ApplicationsFilterState, rhs: ApplicationsFilterState) -> Bool {
        lhs.states == rhs.states && lhs.kinds == rhs.kinds && lhs.locations == rhs.locations
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
