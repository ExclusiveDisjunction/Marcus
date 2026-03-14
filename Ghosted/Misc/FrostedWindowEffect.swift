//
//  FrostedWindowEffect.swift
//  PrismStream
//
//  Created by Hollan Sellars on 3/8/26.
//

import SwiftUI

struct FrostedWindowEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.material = .sidebar
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}
