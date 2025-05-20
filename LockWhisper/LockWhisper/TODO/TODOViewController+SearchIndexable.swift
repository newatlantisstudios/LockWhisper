import Foundation
import CoreData
import UIKit

extension TODOViewController: SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let fetchRequest: NSFetchRequest<TODOItem> = TODOItem.fetchRequest()
        do {
            let items = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            for item in items {
                guard let title = item.title,
                      let createdAt = item.createdAt else { continue }
                
                var decryptedTitle: String
                
                // Check if the title is encrypted
                if TODOEncryptionManager.shared.isEncryptedBase64String(title) {
                    // Try to decrypt the title
                    if let decryptedString = try? TODOEncryptionManager.shared.decryptBase64ToString(title) {
                        decryptedTitle = decryptedString
                    } else {
                        // Fall back to encrypted title if decryption fails
                        decryptedTitle = title
                    }
                } else {
                    // Plain text title
                    decryptedTitle = title
                }
                
                let entry = SearchIndexEntry(
                    id: item.objectID.uriRepresentation().absoluteString,
                    type: .todo,
                    title: decryptedTitle,
                    content: decryptedTitle,
                    keywords: extractKeywords(from: decryptedTitle),
                    timestamp: createdAt,
                    metadata: ["completed": item.completed]
                )
                entries.append(entry)
            }
        } catch {
            print("Failed to fetch TODO items for indexing: \(error)")
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
    
    private func extractKeywords(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { $0.count > 2 }
            .map { $0.lowercased() }
            .prefix(10)
            .map { String($0) }
    }
    
    // Call this when a TODO item is created or updated
    func indexTodoItem(_ item: TODOItem) {
        guard let title = item.title,
              let createdAt = item.createdAt else { return }
        
        var decryptedTitle: String
        
        // Check if the title is encrypted
        if TODOEncryptionManager.shared.isEncryptedBase64String(title) {
            // Try to decrypt the title
            if let decryptedString = try? TODOEncryptionManager.shared.decryptBase64ToString(title) {
                decryptedTitle = decryptedString
            } else {
                // Fall back to encrypted title if decryption fails
                decryptedTitle = title
            }
        } else {
            // Plain text title
            decryptedTitle = title
        }
        
        let entry = SearchIndexEntry(
            id: item.objectID.uriRepresentation().absoluteString,
            type: .todo,
            title: decryptedTitle,
            content: decryptedTitle,
            keywords: extractKeywords(from: decryptedTitle),
            timestamp: createdAt,
            metadata: ["completed": item.completed]
        )
        
        SearchIndexManager.shared.addToIndex(entry)
    }
    
    // Call this when a TODO item is deleted
    func unindexTodoItem(_ item: TODOItem) {
        let id = item.objectID.uriRepresentation().absoluteString
        SearchIndexManager.shared.removeFromIndex(id: id)
    }
}