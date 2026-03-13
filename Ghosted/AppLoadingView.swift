//
//  AppLoadingView.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/13/26.
//

import SwiftUI
import Foundation

public struct AppLoadingView : View {
    @Binding var asyncStream: AsyncStream<String>;
    @State private var currentMessage: String = "Loading";
    
    public var body: some View {
        VStack {
            Image("IconSVG")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .padding()
            
            ProgressView {
                Text(verbatim: currentMessage)
            }
        }.task {
            for await message in asyncStream {
                await MainActor.run {
                    withAnimation {
                        currentMessage = message;
                    }
                }
            }
        }
    }
}
