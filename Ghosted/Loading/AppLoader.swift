//
//  AppLoader.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/13/26.
//

import SwiftUI
import CoreData
import os
import ExDisj

public enum AppLoadingPhase : String, Sendable {
    case loadingData = "Loading Data"
    case reviewingApps = "Reviewing Job Applications"
    case wrappingUp = "Wrapping Up"
}
public struct AppLoadError : Error {
    public let phase: AppLoadingPhase;
    public let inner: any Error;
}



public struct LoadedAppState : Sendable {
    let stack: DataStack;
    let reviewer: StatusReviewer;
}
public extension View {
    func withLoadedApp(_ state: LoadedAppState) -> some View {
        self
            .environment(\.dataStack, state.stack)
            .environment(\.statusReviewer, state.reviewer)
    }
}

@MainActor
@Observable
public class AppLoadingHandle {
    public init() {
        self.loaded = nil;
        self.error = nil;
        self.phase = nil;
    }
    
    public var phase: AppLoadingPhase?;
    public var loaded: LoadedAppState?;
    public var error: AppLoadError?;
    
    public func reset() {
        self.loaded = nil;
        self.error = nil;
        self.phase = nil;
    }
    public func withError(err: any Error) {
        withAnimation {
            self.error = .init(phase: self.phase ?? .loadingData, inner: err);
            self.loaded = nil;
        }
    }
    public func withLoaded(loaded: LoadedAppState) {
        print("App signaled it's load status.")
        withAnimation {
            self.loaded = loaded;
            self.error = nil;
        }
    }
    
    public func updatePhase(to: AppLoadingPhase) {
        withAnimation {
            self.phase = to
        }
    }
}

public actor AppLoader {
    public init(handle: AppLoadingHandle) {
        self.handle = handle;
        self.log = Logger(subsystem: "com.exdisj.Ghosted", category: "App Loader")
    }
    
    private let handle: AppLoadingHandle;
    private let log: Logger;
    
    public func load(beforeComplete: ((DataStack) async throws -> Void)? = nil) async {
        log.info("Begining app loading process.")
        await handle.reset();
        
        log.info("Loading data stack");
        await handle.updatePhase(to: .loadingData);
        let stack: DataStack;
        do {
            stack = try await DataStack.currentContainer();
        }
        catch let e {
            log.error("Unable to load stack due to error \(e)");
            await handle.withError(err: e);
            return;
        }
        
        log.info("Loading status reviewer");
        await handle.updatePhase(to: .reviewingApps);
        let reviewer = StatusReviewer(cx: stack.newBackgroundContext());
        
        log.info("Completed loading main components.");
        await handle.updatePhase(to: .wrappingUp);
        
        if let beforeComplete = beforeComplete {
            do {
                try await beforeComplete(stack);
            }
            catch let e {
                log.error("Post-load action could not be completed due to error \(e)")
                await handle.withError(err: e)
            }
        }
        
        log.info("Completed app loading");
        let completed = LoadedAppState(stack: stack, reviewer: reviewer);
        await handle.withLoaded(loaded: completed);
    }
    public func reset() async throws {
        guard let loaded = await handle.loaded else {
            await handle.reset();
            return;
        }
        
        try loaded.stack.viewContext.save();
        
        await handle.reset();
    }
    
    public func resetAndPerform(action: @escaping (DataStack) async throws -> Void) async throws {
        try await self.reset();
        
        await self.load(beforeComplete: action);
    }
}

fileprivate struct AppLoaderKey : EnvironmentKey {
    static var defaultValue: AppLoader? {
        nil
    }
}
public extension EnvironmentValues {
    var appLoader: AppLoader? {
        get { self[AppLoaderKey.self] }
        set { self[AppLoaderKey.self] = newValue }
    }
}

public struct LoadingGate<Load, Err, Content> : View where Load: View, Err: View, Content: View {
    public init(state: AppLoadingHandle, @ViewBuilder load: @escaping () -> Load, @ViewBuilder err: @escaping (AppLoadError) -> Err, @ViewBuilder content: @escaping () -> Content) {
        self.state = state;
        self.load = load;
        self.err = err;
        self.content = content;
    }
    
    @Bindable private var state: AppLoadingHandle;
    private let load: () -> Load;
    private let err: (AppLoadError) -> Err;
    private let content: () -> Content;
    
    public var body: some View {
        if let error = state.error {
            err(error)
        }
        else if let loaded = state.loaded {
            content()
                .withLoadedApp(loaded)
        }
        else {
            load()
        }
    }
}
extension LoadingGate where Load == AppLoadingView, Err == AppLoadingErrorView {
    public init(state: AppLoadingHandle, @ViewBuilder content: @escaping () -> Content) {
        self.init(
            state: state,
            load: { AppLoadingView(state: state) },
            err: AppLoadingErrorView.init,
            content: content
        )
    }
}
