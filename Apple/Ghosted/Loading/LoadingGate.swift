//
//  LoadingGate.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/14/26.
//

import SwiftUI

public struct LoadingGate<Load, Err, Content> : View where Load: View, Err: View, Content: View {
    public init(state: AppLoadingHandle, @ViewBuilder load: @escaping () -> Load, @ViewBuilder err: @escaping (AppLoadError) -> Err, @ViewBuilder content: @escaping () -> Content) {
        self._state = .init(wrappedValue: state);
        self.load = load;
        self.err = err;
        self.content = content;
    }
    
    @ObservedObject private var state: AppLoadingHandle;
    private let load: () -> Load;
    private let err: (AppLoadError) -> Err;
    private let content: () -> Content;
    
    @ViewBuilder
    private var internalContent: some View {
        switch state.state {
            case .err(let error):
                err(error)
            case .loaded(let loaded):
                content()
                    .withLoadedApp(loaded)
            case .loading:
                load()
        }
    }
    public var body: some View {
        internalContent
            .id(state.state.id)
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
