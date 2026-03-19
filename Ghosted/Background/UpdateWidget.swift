//
//  UpdateWidget.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/17/26.
//

import WidgetKit
import CoreData
import ExDisj
import Combine
import os

public func makeAppliedOnPredicate(forDate: Date, calendar: Calendar) -> NSPredicate? {
    let begin = calendar.startOfDay(for: forDate)
    guard let nextDay = calendar.date(byAdding: .day, value: 1, to: begin),
          let end = calendar.date(
            byAdding: .second,
            value: -1,
            to: nextDay
          ) else {
        return nil;
    }
    
    return NSPredicate(format: "internalAppliedOn BETWEEN {%@, %@}", begin as NSDate, end as NSDate);
}

@discardableResult
func updateAppCountsWidget(cx: NSManagedObjectContext, forDate: Date = .now, calendar: Calendar, fileManager: FileManager = .default) async throws -> AppliedCountEntry {
    let entry = try await cx.perform { [cx] in
        let req = JobApplication.fetchRequest();
        guard let pred = makeAppliedOnPredicate(forDate: forDate, calendar: calendar) else {
            throw CocoaError(.validationInvalidDate)
        }
        req.predicate = pred;
        
        let count = try cx.count(for: req);
        
        return AppliedCountEntry(date: forDate, count: count)
    };
    
    try saveFileContents(data: entry, fileManager: fileManager, forWidget: .appliedCounts)
    return entry;
}
func updateAppCountsWidget(count: Int, forDate: Date = .now, fileManager: FileManager = .default)  throws {
    let entry = AppliedCountEntry(date: forDate, count: count);
    
    try saveFileContents(data: entry, fileManager: fileManager, forWidget: .appliedCounts)
}

public actor NotificationToken {
    private struct InnerToken : @unchecked Sendable {
        let token: NSObjectProtocol;
    }
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        MainActor.sharedUnownedExecutor
    }
    
    @MainActor
    public init(_ inner: NSObjectProtocol, center: NotificationCenter) {
        let token = InnerToken(token: inner);
        self.tokenBox = .init(initialState: token);
        self.center = center;
    }
    deinit {
        self.cancel()
    }
    
    public static nonisolated func createAsync(center: NotificationCenter = .default, forName: NSNotification.Name?, object: (any Sendable)?, perform: @Sendable @escaping (Notification) -> Void) async -> NotificationToken? {
        return await MainActor.run {
            return create(center: center, forName: forName, object: object, perform: perform)
        }
    }
    @MainActor
    public static func create(center: NotificationCenter = .default, forName: NSNotification.Name?, object: Any?, perform: @Sendable @escaping (Notification) -> Void) -> NotificationToken {
        let token = center.addObserver(forName: forName, object: object, queue: OperationQueue.main, using: perform);
        
        return NotificationToken(token, center: center)
    }
    
    private let center: NotificationCenter;
    private let tokenBox: OSAllocatedUnfairLock<InnerToken?>;
    
    public nonisolated func cancel() {
        let token = tokenBox.withLock {
            let old = $0;
            $0 = nil;
            return old;
        };
        
        if let token {
            center.removeObserver(token.token);
        }
    }
}

public final actor WidgetDataManager : Sendable {
    public init(using: DataStack, calendar: Calendar, log: Logger?, onUpdate: (@Sendable (Int) async -> Void)? = nil) async {
        self.log = log;
        self.calendar = calendar;
        self.cx = using.newBackgroundContext();
        self.cx.name = "WidgetDataManagerContext";
        self.cancel = nil;
        self.onUpdate = onUpdate;
        
        self.cancel = await NotificationToken.createAsync(
            forName: .NSManagedObjectContextDidSave,
            object: nil
        ) { [weak self, log] note in
            Self.handleSave(log: log, note: note, inner: self)
        }
        
        log?.info("WidgetUpdater: Widget data manager is configured, listening for notifications.");
    }
    
    private let log: Logger?;
    private let cx: NSManagedObjectContext;
    private let calendar: Calendar;
    private var onUpdate: (@Sendable (Int) async -> Void)?;
    private var cancel: NotificationToken?;
    
    private struct UpdateError : Error { }
    
    public func withUpdateAction(action: @Sendable @escaping (Int) async -> Void) {
        self.onUpdate = action;
    }
    public func withUpdateAction() {
        self.onUpdate = nil;
    }
    
    private func determineIfApplicationsNeedUpdate(forDate: Date, update: Set<NSManagedObjectID>) async throws -> Bool {
        return try await cx.perform { [cx, calendar, log, update] in
            guard let datePred = makeAppliedOnPredicate(forDate: forDate, calendar: calendar) else {
                log?.error("WidgetUpdater: Unable to obtain date predicate for status check. Forcing full check.");
                return true;
            }
            
            let req = JobApplication.fetchRequest();
            req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                datePred,
                NSPredicate(format: "SELF IN %@", update as NSSet)
            ])
            
            return try cx.count(for: req) != 0;
        };
    }
    
    private func proccessChanges(update: [NSManagedObjectID], hadDeleted: Bool, fromContext: NSManagedObjectContext) async {
        let update = Set(update);
        
        guard fromContext.persistentStoreCoordinator == self.cx.persistentStoreCoordinator else {
            log?.warning("WidgetUpdater: Got notification to update, but the notifier is not of the current persistent store. Ignoring.");
            return;
        }
        
        guard hadDeleted || !update.isEmpty else {
            log?.info("WidgetUpdater: No applications were updated or deleted. Ignoring.");
            return;
        }
        
        let date = Date.now;
        
        let willUpdate: Bool;
        if hadDeleted {
            willUpdate = true;
        }
        else if !update.isEmpty {
            do {
                willUpdate = try await determineIfApplicationsNeedUpdate(forDate: date, update: update);
            }
            catch let e {
                log?.error("WidgetUpdater: Unable to fetch application counts due to error \(e.localizedDescription)");
                return;
            }
        }
        else {
            willUpdate = false;
        }
        
        let resultingCount: Int?;
        do {
            if willUpdate {
                log?.info("WidgetUpdater: For context \(fromContext.name ?? "(No Name)", privacy: .public), an update is needed, obtaining new count & updating widget.");
                resultingCount = try await updateAppCountsWidget(cx: cx, forDate: date, calendar: calendar).count;
            }
            else {
                log?.info("WidgetUpdater: For context \(fromContext.name ?? "(No Name)", privacy: .public), an update is not needed. The widget will not be updated.");
                resultingCount = nil;
            }
        }
        catch let e {
            log?.error("WidgetUpdater: Unable to obtain new count, so the widget was not updated. Error: \(e.localizedDescription)")
            resultingCount = nil;
        }
        
        if let resultingCount = resultingCount {
            log?.info("WidgetManager: For context \(fromContext.name ?? "(No Name)", privacy: .public), the widget was updated to contain count \(resultingCount)");
            if let postAction = self.onUpdate {
                await postAction(resultingCount)
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines();
    }
    
    private static nonisolated func handleSave(log: Logger?, note: Notification, inner: WidgetDataManager?) {
        guard let inner = inner else {
            log?.warning("Global WidgetUpdater: No widget manager to update. Ignoring.");
            return;
        }
        guard let info = note.userInfo else {
            log?.warning("Global WidgetUpdater: Got notification to update widget information, but there is no payload. Ignoring.");
            return;
        }
        guard let context = note.object as? NSManagedObjectContext else {
            log?.warning("Global WidgetUpdater: No managed object context was given. Ignoring.")
            return;
        }
        
        log?.info("Global WidgetManager: Processing notification for context named \(context.name ?? "(No Name)", privacy: .public). Unpacking payload.");
        
        let inserted = (info[NSInsertedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let updated = (info[NSUpdatedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        let deleted = (info[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? Set();
        
        let updatedTargets = inserted.union(updated)
            .filter { $0.entity.name == "JobApplication" }
            .map { $0.objectID };
        let hadDeleted = !deleted
            .filter { $0.entity.name == "JobApplication" }
            .isEmpty
        
        log?.info("Global WidgetManager: Processing notification, got \(updatedTargets.count) updated applications, were any deleted? \(hadDeleted). Passing message to specific WidgetManager.");
        
        Task {
            await inner.proccessChanges(update: updatedTargets, hadDeleted: hadDeleted, fromContext: context)
        }
    }
    
    @discardableResult
    public func prepare(forDate: Date) async -> Int? {
        log?.info("WidgetManager: Preparing initial widget update.")
        let result: Int;
        do {
            result = try await updateAppCountsWidget(cx: cx, forDate: forDate, calendar: calendar).count;
        }
        catch let e {
            log?.error("WidgetManager: Unable to perform inital update due to error \(e.localizedDescription)");
            return nil;
        }
        
        log?.info("WidgetManager: Determined that there are \(result) applications completed today");
        
        if let postAction = self.onUpdate {
            await postAction(result)
        }
        
        WidgetCenter.shared.reloadAllTimelines();
        
        return result;
    }
    
}
