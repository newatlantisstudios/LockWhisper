import Foundation
import UIKit

extension CalendarViewController: SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        // Access all events from CalendarManager
        let manager = CalendarManager.shared
        let allEvents = manager.getAllEvents()
        
        for event in allEvents {
            var content = event.title
            
            if let location = event.location {
                content += " \(location)"
            }
            
            if let notes = event.notes {
                content += " \(notes)"
            }
            
            let keywords = [
                event.title,
                event.location,
                formatDate(event.startDate)
            ].compactMap { $0 }
            
            let entry = SearchIndexEntry(
                id: event.id.uuidString,
                type: .event,
                title: event.title,
                content: content,
                keywords: keywords,
                timestamp: event.startDate,
                metadata: [
                    "location": event.location ?? "",
                    "notes": event.notes ?? "",
                    "endDate": event.endDate.timeIntervalSince1970,
                    "color": event.color
                ]
            )
            entries.append(entry)
        }
        
        return entries
    }
    
    func updateSearchIndex() {
        let entries = buildSearchIndexEntries()
        SearchIndexManager.shared.updateIndex(entries)
    }
    
    func removeFromSearchIndex(id: String) {
        SearchIndexManager.shared.removeFromIndex(id: id)
    }
    
    // Call this when events are loaded or modified
    func indexCalendarEvents() {
        updateSearchIndex()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}