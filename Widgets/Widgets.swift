//
//  Widgets.swift
//  Widgets
//
//  Created by Hollan Sellars on 3/17/26.
//

import WidgetKit
import SwiftUI
import os


extension AppliedCountEntry : TimelineEntry {
    
}

let logger: Logger = Logger(subsystem: "com.exdisj.Ghosted", category: "Widget")

struct AppliedCountProvider : TimelineProvider {
    func placeholder(in context: Context) -> AppliedCountEntry {
        logger.info("Widget: Obtaining a placeholder")
        return AppliedCountEntry(date: .now, count: 7)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AppliedCountEntry) -> Void) {
        let entry = placeholder(in: context);
        completion(entry)
    }
    
    func obtainEntries() -> [AppliedCountEntry] {
        var entries: [AppliedCountEntry] = [];
        
        logger.info("Widget: Attempting to resolve the current application counts")
        
        do {
            let loadedEntry: AppliedCountEntry? = try getFileContents(forWidget: .appliedCounts);
            if let loadedEntry  {
                logger.info("Obtained an entry, count \(loadedEntry.count) for date \(loadedEntry.date)");
                entries.append(loadedEntry);
            }
            else {
                logger.warning("Widget: The file could be read, but it contained no information");
            }
        }
        catch let e {
            logger.error("Widget: Unable to obtain the shared group contents due to error \(e.localizedDescription)")
        }
        
        let calendar = Calendar.current;
        
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) {
            entries.append(.init(date: tomorrow, count: 0))
        }
        
        logger.info("Completd widget update with \(entries.count) entry/entries");
        return entries;
    }

    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AppliedCountEntry>) -> Void) {
        completion(.init(entries: obtainEntries(), policy: .atEnd))
    }
}

struct WidgetsEntryView : View {
    let entry: AppliedCountEntry;

    var body: some View {
        VStack(alignment: .leading) {
            Text("Applications Today")
                .font(.title2)
            
            HStack {
                Spacer()
                Text(entry.count, format: .number)
                    .font(.system(size: 50))
            }
        }.foregroundStyle(.white)
    }
}

struct Widgets: Widget {
    public init() {
        debugPrint("Started widget process")
        logger.info("Widget: Extension Process Started")
    }
    
    let kind: String = "Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AppliedCountProvider()) { entry in
            WidgetsEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color("WidgetColor")
                }
        }
        .configurationDisplayName("Applied Job Count")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    Widgets()
} timeline: {
    let provider = AppliedCountProvider();
    let entries = provider.obtainEntries();
    
    entries[0]
    (entries.count == 1) ? AppliedCountEntry(date: .now, count: 0) : entries[1]
}
