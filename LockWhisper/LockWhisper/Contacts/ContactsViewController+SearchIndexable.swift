import Foundation
import UIKit

extension ContactsViewController: SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        // Use the loaded contacts array directly
        for (index, contact) in contacts.enumerated() {
            let content = [
                contact.name,
                contact.email1,
                contact.email2,
                contact.phone1,
                contact.phone2,
                contact.notes
            ].compactMap { $0 }.joined(separator: " ")
            
            let keywords = [
                contact.name,
                contact.email1,
                contact.email2
            ].compactMap { $0 }
            
            let entry = SearchIndexEntry(
                id: "\(index)",
                type: .contact,
                title: contact.name,
                content: content,
                keywords: keywords,
                timestamp: Date()
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
    
    // Call this after contacts are loaded or modified
    func indexContacts() {
        updateSearchIndex()
    }
}