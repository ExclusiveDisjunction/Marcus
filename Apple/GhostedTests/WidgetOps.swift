//
//  WidgetOps.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/18/26.
//

import Testing
import Ghosted
import CoreData
import ExDisj
import os
import XCTest

struct WidgetDataFiller : ContainerDataFiller {
    func fill(context: NSManagedObjectContext) throws {
        for i in 1...4 {
            guard let date = Calendar.current.date(byAdding: .day, value: Int.random(in: (-5)...(-2)), to: .now) else {
                continue;
            }
            let job = JobApplication(context: context);
            
            job.position = "Position \(i)";
            job.company = "Company \(i)"
            job.state = .applied;
            job.lastStatusUpdated = date;
            job.appliedOn = date;
            job.kind = .fullTime
            job.locationKind = .onSite;
        }
    }
}

@Suite("WidgetOps")
struct WidgetOps {
    init() async throws {
        
        cal = Calendar.current;
        log = Logger(subsystem: "com.exdisj.Ghosted", category: "Unit Testing")
    }
    
    let cal: Calendar;
    let log: Logger;
    
    private func prepare() async throws -> (DataStack, NSManagedObjectContext, WidgetDataManager) {
        let stack = try await DataStack(
            desc: .builder(
                filler: WidgetDataFiller(),
                backing: .inMemory()
            )
        )
        let cx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType);
        cx.persistentStoreCoordinator = stack.coordinator;
        stack.viewContext.automaticallyMergesChangesFromParent = true;
        
        let manager = await WidgetDataManager(using: stack, calendar: cal, log: log);
        try await manager.prepare(forDate: .now);
        
        return (stack, cx, manager);
    }
    
    @Test("noAction")
    func noAction() async throws {
        // Do nothing, verify that it does not run.
        let (stack, cx, manager) = try await prepare();
        
        try await Task.sleep(for: .seconds(0.3)); //Ensure it is loaded
        await confirmation(expectedCount: 0) { confirm in
            await manager.withUpdateAction { count in
                confirm()
            }
        };
        
        let (asyncStream, continuation) = AsyncStream<Int>.makeStream();
        await manager.withUpdateAction { count in
            continuation.yield(count)
        }
        
        guard let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: .now) else {
            throw CocoaError(.validationInvalidDate);
        }
        
        try await cx.perform { [cx] in
            let newApp = JobApplication(context: cx);
            newApp.company = "Test";
            newApp.position = "test";
            newApp.appliedOn = twoDaysAgo;
            newApp.lastStatusUpdated = twoDaysAgo;
            newApp.state = .applied;
            newApp.location = "";
            newApp.locationKind = .onSite;
            
            try cx.save();
        }
        
        try await Task.sleep(for: .seconds(0.3)); //Ensure it is loaded
        
        // Since we do not update anything for today, we expect that this is never called.
        let updatedCount = try await requireAsyncCall(
            expectedCalls: 0,
            desc: "Obtain the updated count",
            timeout: 1.0) { complete in
                var asyncIter = asyncStream.makeAsyncIterator();
                
                let count = await asyncIter.next();
                complete();
                return count;
            };
        
        try #require(updatedCount == nil);
    }
    
    @Test("forAddingAndDelete")
    func forAddingAndDelete() async throws {
        let (stack, cx, manager) = try await prepare();
        
        let (asyncStream, continuation) = AsyncStream<Int>.makeStream();
        await manager.withUpdateAction { count in
            continuation.yield(count)
        }
        
        let id = try await cx.perform { [cx] in
            let newApp = JobApplication(context: cx);
            newApp.company = "Test";
            newApp.position = "test";
            newApp.appliedOn = .now;
            newApp.lastStatusUpdated = newApp.appliedOn;
            newApp.state = .applied;
            newApp.location = "";
            newApp.locationKind = .onSite;
            
            try cx.save();
            
            return newApp.objectID;
        }
        
        try await Task.sleep(for: .seconds(0.3)); //Ensure it is loaded
        var updatedCount = try await requireAsyncCall(
            desc: "Obtain the updated count",
            timeout: 10.0) { complete in
                var asyncIter = asyncStream.makeAsyncIterator();
                
                let count = await asyncIter.next();
                complete();
                return count;
            };
        
        try #require(updatedCount == 1);
        
        //Now remove the new element.
        try await cx.perform { [cx, id] in
            cx.delete( cx.object(with: id) )
            
            try cx.save();
        }
        
        try await Task.sleep(for: .seconds(0.3)); //Ensure it is loaded
        updatedCount = try await requireAsyncCall(
            desc: "Obtain the updated count",
            timeout: 10.0
        ) { complete in
            var asyncIter = asyncStream.makeAsyncIterator();
            
            let count = await asyncIter.next();
            complete();
            return count;
        };
        
        try #require(updatedCount == 0);
    }
}

public enum AsyncWaitingError : Error {
    case inner(any Error)
    case timeout
    case miscFailure
    case expectedNoCalls
}

public struct AsyncCompletion : Sendable {
    fileprivate init(_ inner: XCTestExpectation) {
        self.inner = inner;
    }
    private let inner: XCTestExpectation;
    
    public func callAsFunction() {
        inner.fulfill()
    }
}

public func requireAsyncCall<T>(
    expectedCalls: Int = 1,
    desc: String? = nil,
    timeout: TimeInterval,
    performing: @Sendable @escaping (AsyncCompletion) async throws -> T
) async throws -> T?
where T: Sendable {
    let expect = if let desc {
        XCTestExpectation(description: desc);
    }
    else {
        XCTestExpectation();
    };
    
    if expectedCalls == 0 {
        expect.isInverted = true;
    }
    else {
        expect.expectedFulfillmentCount = expectedCalls;
    }
    
    let task = Task { [expect, performing] in
        try await performing(AsyncCompletion(expect))
    };
    
    let waitingResult = await XCTWaiter.fulfillment(of: [expect], timeout: timeout);
    if expectedCalls == 0 {
        if waitingResult == .completed || waitingResult == .invertedFulfillment {
            return nil;
        }
        else {
            throw AsyncWaitingError.expectedNoCalls;
        }
    }
    else {
        if waitingResult == .completed {
            return try await task.value;
        }
        else if waitingResult == .timedOut {
            throw AsyncWaitingError.timeout;
        }
        else  {
            throw AsyncWaitingError.miscFailure
        }
    }
}
