//
//  StatusReviewer.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/11/26.
//

import SwiftUI
import Observation
import os
import ExDisj

public struct StaticApplicationStatusSnapshot : Identifiable, Sendable {
    public init(id: NSManagedObjectID, position: String, company: String, current: JobApplicationState, lastUpdate: Date) {
        self.id = id;
        self.position = position;
        self.company = company;
        self.currentState = current;
        self.lastUpdated = lastUpdate;
    }
    
    public let id: NSManagedObjectID;
    public let currentState: JobApplicationState;
    public let position: String;
    public let company: String;
    public let lastUpdated: Date;
}


@MainActor
@Observable
public class ApplicationStatusSnapshot : Identifiable {
    public init(from: StaticApplicationStatusSnapshot) {
        self.id = from.id;
        self.position = from.position;
        self.company = from.company;
        self.currentState = from.currentState;
        self.updateStateTo = from.currentState;
        self.lastUpdated = from.lastUpdated;
    }
    
    @ObservationIgnored public let id: NSManagedObjectID;
    @ObservationIgnored public let currentState: JobApplicationState;
    @ObservationIgnored public let position: String;
    @ObservationIgnored public let company: String;
    @ObservationIgnored public let lastUpdated: Date;
    public var updateStateTo: JobApplicationState;
    /// Allows the user to indicate that they do not want to change the job status
    public var updatedFlag: Bool = false;
    
    public var didUpdate: Bool {
        updateStateTo != currentState || updatedFlag
    }
}

@Observable
public class StatusReviewer {
    public init(container: NSPersistentContainer) {
        self.cx = container.newBackgroundContext();
    }
    /// Constructs the status reviewer from `NSManagedObjectContext` instances.
    /// - Parameters:
    ///     - cx: The background thread model context, used to process and update information off the main thread.
    ///     - vcx: The view context, or main actor bound model context. Used to present information to the UI.
    public init(cx: NSManagedObjectContext) {
        self.cx = cx;
    }
    
    @ObservationIgnored private let cx: NSManagedObjectContext;
    
    /// A set of ``JobApplicationState`` values, represented by their raw value, that the ``StatusReviewer``  should flag for updating.
    public static let interestingApplicationStates = Set<JobApplicationState.RawValue>(
        [
            JobApplicationState.applied,
            JobApplicationState.inInterview,
            JobApplicationState.underReview
        ].map { $0.rawValue }
    );
    
    public nonisolated func compute(log: Logger, daysToCheck: Int, relativeTo: Date, calendar: Calendar) async throws -> [NSManagedObjectID : ApplicationStatusSnapshot] {
        
        let toUpdate: [StaticApplicationStatusSnapshot] = try await cx.perform { [cx] in
            let req = JobApplication.fetchRequest();
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "lastStatusUpdated != nil"),
                NSPredicate(format: "internalState IN %@", Self.interestingApplicationStates)
            ]);
            
            let applications = try cx.fetch(req);
            
            var result = [StaticApplicationStatusSnapshot]();
            let today = calendar.startOfDay(for: relativeTo);
            for app in applications {
                guard let rawLastUpdated = app.lastStatusUpdated else {
                    log.info("\(app.position) has no last updated date, skipping")
                    continue;
                }
                
                let lastUpdated = calendar.startOfDay(for: rawLastUpdated)
                guard let daysBetween = calendar.dateComponents([.day], from: lastUpdated, to: today).day else {
                    log.warning("Could not determine days between today and last updated for application \(app.position)")
                    continue;
                }
                
                if daysBetween >= daysToCheck {
                    result.append(
                        StaticApplicationStatusSnapshot(
                            id: app.objectID,
                            position: app.position,
                            company: app.company,
                            current: app.state,
                            lastUpdate: lastUpdated
                        )
                    )
                }
            }
            
            return result;
        };
        
        return await Task { @MainActor [toUpdate] in
            var result = [NSManagedObjectID : ApplicationStatusSnapshot]();
            
            for app in toUpdate {
                result[app.id] = ApplicationStatusSnapshot(from: app);
            }
            
            return result;
        }.value;
    }
    
    public nonisolated func completeUpdate(results: [NSManagedObjectID : ApplicationStatusSnapshot]) async throws {
        
    }
}

public struct StatusReviewPresenter : View {
    @Bindable var source: StatusReviewer;
    public let given: [NSManagedObjectID : ApplicationStatusSnapshot];
    
    @Binding var bySection: [(JobApplicationState, [ApplicationStatusSnapshot])];
    @Binding var selection: Set<NSManagedObjectID>;
    
    private func move(ids: Set<NSManagedObjectID>, to: JobApplicationState) {
        var toAdd: [ApplicationStatusSnapshot] = [];
        
        var bySection = self.bySection; //Keeps UI stable until the computation is complete.
        
        for (currentState, applications) in bySection {
            var targetIndices = IndexSet();
            var targets = [ApplicationStatusSnapshot]();
            for (i, app) in applications.enumerated() {
                if ids.contains(app.id) {
                    targetIndices.insert(i)
                    targets.append(app);
                }
            }
            
            toAdd.append(contentsOf: targets);
            // Since our applications is not going to update our true state, we have to manage it here.
            bySection[Int(currentState.rawValue)].1.remove(atOffsets: targetIndices);
        }
        
        bySection[Int(to.rawValue)].1.append(contentsOf: toAdd);
        for state in toAdd {
            state.updateStateTo = to;
        }
        
        withAnimation {
            self.bySection = bySection;
        }
    }
    private func toggleUpdated(ids: Set<NSManagedObjectID>) {
        withAnimation {
            for (_, applications) in bySection {
                for app in applications {
                    if ids.contains(app.id) {
                        app.updatedFlag.toggle()
                    }
                }
            }
        }
    }
    /// Turns the `[NSManagedObjectID : ApplicationStatusSnapshot]` into `[(JobApplicationState), [ApplicationStatusSnapshot])]`.
    private func prepare(from: [NSManagedObjectID : ApplicationStatusSnapshot]) -> [(JobApplicationState, [ApplicationStatusSnapshot])] {
        var result: [(JobApplicationState, [ApplicationStatusSnapshot])] = JobApplicationState.allCases
            .sorted(using: KeyPathComparator(\.rawValue))
            .map { ($0, []) }
        
        for (_, snapshot) in from {
            let index = Int(snapshot.currentState.rawValue);
            
            result[index].1.append(snapshot)
        }
        
        return result;
    }
    /// Turns the `[(JobApplicationState), [ApplicationStatusSnapshot])]` into `[NSManagedObjectID : ApplicationStatusSnapshot]`.
    private func demangle() -> [NSManagedObjectID : ApplicationStatusSnapshot] {
        var result = [NSManagedObjectID : ApplicationStatusSnapshot]();
        
        for (_, snapshots) in bySection {
            for app in snapshots {
                result[app.id] = app
            }
        }
        
        return result;
    }
    
    
    public var body: some View {
        List(selection: $selection) {
            ForEach(bySection, id: \.0) { (state, entries) in
                Section(state.display) {
                    ForEach(entries) { app in
                        VStack(alignment: .leading) {
                            HStack {
                                if !app.didUpdate {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 5, height: 5)
                                }
                                
                                Text(verbatim: "\(app.position) at \(app.company)")
                            }
                            
                            if app.currentState != app.updateStateTo {
                                HStack {
                                    Text(app.currentState.display)
                                    Image(systemName: "arrow.right")
                                    Text(app.updateStateTo.display)
                                }
                            }
                            else {
                                Text(verbatim: "Last Updated \(app.lastUpdated.formatted(date: .numeric, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }.contextMenu(forSelectionType: NSManagedObjectID.self) { selection in
            Section("Mark as") {
                Button("Updated/To Review") {
                    toggleUpdated(ids: selection)
                }
                
                ForEach(JobApplicationState.allCases, id: \.id) { state in
                    Button {
                        move(ids: selection, to: state)
                    } label: {
                        Text(state.display)
                    }
                }
            }
        }.onAppear {
            let results = prepare(from: given)
            withAnimation {
                bySection = results;
            }
        }
    }
}

public struct StatusReviewSheet : View {
    @Bindable var source: StatusReviewer;
    public let given: [NSManagedObjectID : ApplicationStatusSnapshot];
    
    @State var bySection: [(JobApplicationState, [ApplicationStatusSnapshot])] = .init();
    @State var selection: Set<NSManagedObjectID> = .init();
    @Environment(\.dismiss) private var dismiss;
    
    private func submit() {
        
    }
    
    public var body: some View {
        SheetBody("Job Application Status Review") {
            StatusReviewPresenter(
                source: source,
                given: given,
                bySection: $bySection,
                selection: $selection
            )
        } actions: {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }.buttonStyle(.bordered)
            
            Button {
                submit()
            } label: {
                Text("Save")
            }.buttonStyle(.borderedProminent)
        }
    }
}

fileprivate struct StatusReviewerKey : EnvironmentKey {
    typealias Value = StatusReviewer?;
    
    static var defaultValue: StatusReviewer? { nil }
}
public extension EnvironmentValues {
    var statusReviewer: StatusReviewer? {
        get { self[StatusReviewerKey.self] }
        set { self[StatusReviewerKey.self] = newValue }
    }
}

fileprivate struct StatusReviewPreview : PreviewModifier {
    static func makeSharedContext() async throws -> Context {
        let result = DataStack.shared.debugContainer;
        
        let cx = result.viewContext;
        cx.performAndWait { [cx] in
            let states: [JobApplicationState] = [
                .applied,
                .applied,
                .inInterview,
                .inInterview,
                .underReview,
                .rejected
            ];
            
            let targetDate = Calendar.current.date(byAdding: .day, value: -15, to: Calendar.current.startOfDay(for: .now))!;
            
            for (i, state) in states.enumerated() {
                let job = JobApplication(context: cx);
                job.position = "Position \(i + 1)"
                job.company = "Company \(i + 1)"
                job.state = state
                job.appliedOn = targetDate
                job.lastStatusUpdated = targetDate
                job.kind = .fullTime
                job.locationKind = .onSite
            }
        };
        
        try cx.save();
        let reviewer = StatusReviewer(cx: result.newBackgroundContext());
        return (result, reviewer);
    }
    
    func body(content: Content, context: (NSPersistentContainer, StatusReviewer)) -> some View {
        content
            .environment(\.managedObjectContext, context.0.viewContext)
            .environment(\.statusReviewer, context.1)
    }
}

@available(macOS 15, iOS 18, *)
extension PreviewTrait where T == Preview.ViewTraits {
    fileprivate static let statusReview: Self = .modifier(StatusReviewPreview())
}


@available(iOS 18, macOS 15, *)
#Preview(traits: .statusReview) {
    @Previewable @Environment(\.statusReviewer) var statusReviewer;
    @Previewable @State var loaded: [NSManagedObjectID : ApplicationStatusSnapshot]? = nil;
    @Previewable @State var error: String? = nil;
    
    VStack {
        if let error = error {
            Text(verbatim: error)
        }
        else if let loaded = loaded {
            StatusReviewSheet(source: statusReviewer!, given: loaded)
        }
        else {
            ProgressView("Loading")
                .task {
                    do {
                        try await Task.sleep(for: .seconds(0.5))
                        
                        let result = try await statusReviewer!.compute(log: Logger(), daysToCheck: 14, relativeTo: .now, calendar: .current)
                        
                        await MainActor.run {
                            withAnimation {
                                loaded = result;
                            }
                        }
                    }
                    catch let e {
                        await MainActor.run {
                            withAnimation {
                                error = e.localizedDescription;
                            }
                        }
                    }
                }
        }
    }.frame(width: 600, height: 400)
}
