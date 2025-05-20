import Foundation
import UIKit

extension PasswordViewController: SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        // Load passwords directly since we already have them
        for (index, password) in passwords.enumerated() {
            let entry = SearchIndexEntry(
                id: "\(index)",
                type: .password,
                title: password.title,
                content: password.title,
                keywords: [password.title],
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
    
    // Call this after passwords are loaded or modified
    func indexPasswords() {
        updateSearchIndex()
    }
}