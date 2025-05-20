import Foundation
import CoreData
import UIKit

extension NotepadViewController: SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        do {
            let notes = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            for note in notes {
                guard let storedText = note.text,
                      let createdAt = note.createdAt else { continue }
                
                var decryptedText: String
                
                // Try to decrypt the text first
                if let decryptedString = try? NoteEncryptionManager.shared.decryptBase64ToString(storedText) {
                    decryptedText = decryptedString
                } else {
                    // Fall back to plain text if decryption fails
                    decryptedText = storedText
                }
                
                // Extract title from first line
                let lines = decryptedText.components(separatedBy: CharacterSet.newlines)
                let title = lines.first ?? "Untitled Note"
                
                // Create search index entry
                let entry = SearchIndexEntry(
                    id: note.objectID.uriRepresentation().absoluteString,
                    type: .note,
                    title: title,
                    content: decryptedText,
                    keywords: extractKeywords(from: decryptedText),
                    timestamp: createdAt
                )
                entries.append(entry)
            }
        } catch {
            print("Failed to fetch notes for indexing: \(error)")
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
        // Simple keyword extraction - can be enhanced
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { $0.count > 3 }
            .map { $0.lowercased() }
            .prefix(10)
            .map { String($0) }
    }
    
    // Call this when a note is created or updated
    func indexNote(_ note: Note) {
        guard let storedText = note.text,
              let createdAt = note.createdAt else { return }
        
        var decryptedText: String
        
        // Try to decrypt the text first
        if let decryptedString = try? NoteEncryptionManager.shared.decryptBase64ToString(storedText) {
            decryptedText = decryptedString
        } else {
            // Fall back to plain text if decryption fails
            decryptedText = storedText
        }
        
        let lines = decryptedText.components(separatedBy: CharacterSet.newlines)
        let title = lines.first ?? "Untitled Note"
        
        let entry = SearchIndexEntry(
            id: note.objectID.uriRepresentation().absoluteString,
            type: .note,
            title: title,
            content: decryptedText,
            keywords: extractKeywords(from: decryptedText),
            timestamp: createdAt
        )
        
        SearchIndexManager.shared.addToIndex(entry)
    }
    
    // Call this when a note is deleted
    func unindexNote(_ note: Note) {
        let id = note.objectID.uriRepresentation().absoluteString
        SearchIndexManager.shared.removeFromIndex(id: id)
    }
}