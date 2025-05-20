import Foundation
import UIKit

// Don't implement SearchIndexable yet - we need to fix the SearchIndexable protocol first
// This will be implemented in a future update
extension CalendarViewController {
    func buildCalendarSearchEntries() -> [SearchIndexEntry] {
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
    
    func updateCalendarSearchIndex() {
        let entries = buildCalendarSearchEntries()
        SearchIndexManager.shared.updateIndex(entries)
    }
    
    func removeCalendarEventFromSearchIndex(id: String) {
        SearchIndexManager.shared.removeFromIndex(id: id)
    }
    
    // Call this when events are loaded or modified
    func indexCalendarEvents() {
        updateCalendarSearchIndex()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}