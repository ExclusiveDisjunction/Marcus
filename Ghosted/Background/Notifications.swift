//
//  Notifications.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/18/26.
//

import BackgroundTasks
import ExDisj
import CoreData
import os

/*
 
    We are going to use BGProcessingTask to handle determining if a follow up notification should be activated.
 
    This may not be a quick operation, so we will use BGProcessingTask.
 */

public enum BackgroundTasks : String, Sendable, Equatable, Hashable, CustomStringConvertible {
    case followUps = "com.exdisj.Ghosted.FollowUpNotification.Processing"
    
    public var description: String {
        switch self {
            case .followUps: "Follow Up Reminders"
        }
    }
    
    public var operation: Operation {
        switch self {
            case .followUps: FollowUpsBackgroundOperation()
        }
    }
}

public class AsyncOperation : Operation, @unchecked Sendable {
    public override init() {
        super.init()
    }
    
    private var _isExecuting: Bool = false;
    private var _isFinished: Bool = false;
    
    public override var isAsynchronous: Bool { true }
    public private(set) override var isExecuting: Bool {
        get { _isExecuting }
        set {
            willChangeValue(forKey: "isExecuting")
            _isExecuting = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    public private(set) override var isFinished: Bool {
        get { _isFinished }
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    open func mainAsync() async -> Void {
        
    }
    
    public override func start() {
        guard !isCancelled else {
            finalize()
            return;
        }
        
        isExecuting = true;
        
        Task {
            await self.mainAsync()
            finalize()
        }
    }
    
    public override func finalize() {
        isExecuting = false;
        isFinished = true;
    }
}

public class FollowUpsBackgroundOperation : AsyncOperation, @unchecked Sendable {
    public override func mainAsync() async {
        print("Within async operation!!!")
    }
}

public func registerTask(logger: Logger?, kind: BackgroundTasks) {
    let didRegister = BGTaskScheduler.shared.register(
        forTaskWithIdentifier: kind.rawValue,
        using: nil
    ) { task in
        performFollowUpNotification(task as! BGProcessingTask, kind: kind);
    }
    
    if didRegister {
        logger?.info("Background: \(kind) was succesfully registered.");
    }
    else {
        logger?.error("Background: Unable to register the background task for \(kind)")
    }
}

public func scheduleBackgroundProcessing(forKind: BackgroundTasks, runOn date: Date, logger: Logger?) {
    let req = BGProcessingTaskRequest(identifier: forKind.rawValue);
    req.earliestBeginDate = date;
    
    logger?.info("Background: Submitting new task request for type \(forKind), earliest start: \(date)");
    do {
        try BGTaskScheduler.shared.submit(req);
        logger?.info("Background: Sucessfully submitted request for \(forKind)");
    }
    catch let e {
        logger?.error("Background: Unable to request background work for \(forKind)");
    }
}

struct TaskWrapper : @unchecked Sendable {
    let inner: BGProcessingTask;
}

public func performFollowUpNotification(_ task: BGProcessingTask, kind: BackgroundTasks) {
    let logger = Logger(subsystem: "com.exdisj.Ghosted", category: "Background");
    let task = TaskWrapper(inner: task);
    
    guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) else {
        logger.error("Background: Unable to determine a new date for background processing.");
        return;
    }
    
    scheduleBackgroundProcessing(forKind: kind, runOn: newDate, logger: logger);
    
    let op = kind.operation;
    let queue = OperationQueue();
    queue.maxConcurrentOperationCount = 1;
    
    task.inner.expirationHandler = {
        op.cancel()
    }
    op.completionBlock = {
        task.inner.setTaskCompleted(success: !op.isCancelled)
    }
    
    queue.addOperation(op);
}
