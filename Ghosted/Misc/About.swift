//
//  About.swift
//  Ghosted
//
//  Created by Hollan Sellars on 3/14/26.
//

import SwiftUI

public struct AboutView : View {
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown"
    }
    private var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "Unknown"
    }
    
    public var body: some View {
        VStack {
            Image("IconSVG")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .padding()
            
            Text("Ghosted")
                .font(.title)
            Text("Job Hunt Organizer")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            Text(verbatim: "Version \(appVersion), Build \(buildNumber)")
            Text("Written by Hollan Sellars (ExDisj)")
                .padding(.bottom)
            
            Text("For support, please visit:")
            Text("https://exdisj.com/products/Ghosted")
            Text("Or reach out to:")
            Text("support@exdisj.com")
        }.padding()
    }
}

@available(macOS 14, *)
#Preview {
    AboutView()
        .background(FrostedWindowEffect().ignoresSafeArea())
}
