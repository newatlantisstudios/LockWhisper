import Foundation
import CoreData
import UIKit

class SearchIndexCoordinator {
    static let shared = SearchIndexCoordinator()
    
    private init() {}
    
    func rebuildFullIndex() {
        DispatchQueue.global(qos: .background).async {
            var allEntries: [SearchIndexEntry] = []
            
            // Index Notes
            allEntries.append(contentsOf: self.indexNotes())
            
            // Index TODO items
            allEntries.append(contentsOf: self.indexTodoItems())
            
            // Index Passwords
            allEntries.append(contentsOf: self.indexPasswords())
            
            // Index Contacts
            allEntries.append(contentsOf: self.indexContacts())
            
            // Index PGP Conversations
            allEntries.append(contentsOf: self.indexPGPConversations())
            
            // Index Files from File Vault
            allEntries.append(contentsOf: self.indexFiles())
            
            // Index Voice Memos
            allEntries.append(contentsOf: self.indexVoiceMemos())
            
            // Index Calendar Events
            allEntries.append(contentsOf: self.indexCalendarEvents())
            
            // Update the search index
            SearchIndexManager.shared.updateIndex(allEntries)
        }
    }
    
    private func indexNotes() -> [SearchIndexEntry] {
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
                entries.append(entry)
            }
        } catch {
            print("Failed to index notes: \(error)")
        }
        
        return entries
    }
    
    private func indexTodoItems() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let fetchRequest: NSFetchRequest<TODOItem> = TODOItem.fetchRequest()
        do {
            let items = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            for item in items {
                guard let storedTitle = item.title,
                      let createdAt = item.createdAt else { continue }
                
                var decryptedTitle: String
                
                // Check if the title is encrypted
                if TODOEncryptionManager.shared.isEncryptedBase64String(storedTitle) {
                    // Try to decrypt the title
                    if let decryptedString = try? TODOEncryptionManager.shared.decryptBase64ToString(storedTitle) {
                        decryptedTitle = decryptedString
                    } else {
                        // Fall back to stored title if decryption fails
                        decryptedTitle = storedTitle
                    }
                } else {
                    // Plain text title
                    decryptedTitle = storedTitle
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
            print("Failed to index TODO items: \(error)")
        }
        
        return entries
    }
    
    private func indexPasswords() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        // We need to handle both regular and fake mode passwords
        let passwordsKey = "savedPasswords"
        let actualKey = FakePasswordManager.shared.getUserDefaultsKey(for: passwordsKey)
        
        if let data = UserDefaults.standard.data(forKey: actualKey) {
            do {
                let decoder = JSONDecoder()
                let encryptionManager = PasswordEncryptionManager.shared
                
                var passwords: [PasswordEntry] = []
                
                // Try to decrypt if the data is encrypted
                if encryptionManager.isEncryptedData(data) {
                    let decryptedData = try encryptionManager.decryptData(data)
                    passwords = try decoder.decode([PasswordEntry].self, from: decryptedData)
                } else {
                    // Handle legacy unencrypted data
                    if let savedPasswords = try? decoder.decode([PasswordEntry].self, from: data) {
                        passwords = savedPasswords
                    }
                }
                
                // Create search entries for each password
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
            } catch {
                print("Failed to index passwords: \(error)")
            }
        }
        
        return entries
    }
    
    private func indexContacts() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        if let data = UserDefaults.standard.data(forKey: Constants.savedContacts) {
            do {
                let decoder = JSONDecoder()
                var contacts: [ContactContacts] = []
                
                // We need to use the ContactsViewController's encryption logic
                // For now, we'll implement a simplified version
                if data.count > 0 && data[0] == 1 { // Check for encryption marker
                    // This is encrypted data - we'd need the proper key to decrypt
                    // For SearchIndexCoordinator, we'll skip encrypted contacts for now
                    // Since the ContactsViewController handles its own indexing
                    return entries
                } else {
                    // Try to decode unencrypted data
                    if let decodedContacts = try? decoder.decode([ContactContacts].self, from: data) {
                        contacts = decodedContacts
                    }
                }
                
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
            } catch {
                print("Failed to index contacts: \(error)")
            }
        }
        
        return entries
    }
    
    private func indexPGPConversations() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        // This assumes conversations are stored in UserDefaults - adjust based on actual implementation
        if let conversationsData = UserDefaults.standard.data(forKey: Constants.encryptedPGPConversations),
           let conversations = try? JSONSerialization.jsonObject(with: conversationsData) as? [[String: Any]] {
            
            for conversation in conversations {
                if let contact = conversation["contact"] as? String,
                   let messages = conversation["messages"] as? [[String: Any]] {
                    
                    let lastMessage = messages.last?["content"] as? String ?? ""
                    let entry = SearchIndexEntry(
                        id: contact,
                        type: .pgpMessage,
                        title: "Conversation with \(contact)",
                        content: lastMessage,
                        keywords: [contact],
                        timestamp: Date()
                    )
                    entries.append(entry)
                }
            }
        }
        
        return entries
    }
    
    private func indexFiles() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first else { return entries }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                
                // Get file attributes
                var creationDate = Date()
                var fileSize: Int64 = 0
                
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                    creationDate = resourceValues.creationDate ?? Date()
                    fileSize = Int64(resourceValues.fileSize ?? 0)
                } catch {
                    print("Error getting file attributes: \(error)")
                }
                
                let fileExtension = fileURL.pathExtension.lowercased()
                
                let entry = SearchIndexEntry(
                    id: fileURL.absoluteString,
                    type: .file,
                    title: fileName,
                    content: fileName,
                    keywords: [fileName, fileExtension],
                    timestamp: creationDate,
                    metadata: ["fileSize": fileSize]
                )
                entries.append(entry)
            }
        } catch {
            print("Failed to index files: \(error)")
        }
        
        return entries
    }
    
    private func indexVoiceMemos() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return entries
        }
        
        let mediaDirectory = documentsDirectory.appendingPathComponent("MediaLibrary")
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: mediaDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            for fileURL in fileURLs {
                // Check if it's a voice memo (simplified check based on filename)
                let filename = fileURL.lastPathComponent
                if filename.contains("voiceMemo_") {
                    var creationDate = Date()
                    
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                        creationDate = resourceValues.creationDate ?? Date()
                    } catch {
                        print("Error getting file attributes: \(error)")
                    }
                    
                    let displayName = formatVoiceMemoName(filename)
                    
                    let entry = SearchIndexEntry(
                        id: fileURL.absoluteString,
                        type: .voiceMemo,
                        title: displayName,
                        content: displayName,
                        keywords: [displayName, "voice memo", "audio"],
                        timestamp: creationDate
                    )
                    entries.append(entry)
                }
            }
        } catch {
            print("Failed to index voice memos: \(error)")
        }
        
        return entries
    }
    
    private func formatVoiceMemoName(_ fileName: String) -> String {
        let nameWithoutExt = fileName.replacingOccurrences(of: ".enc", with: "")
        
        if nameWithoutExt.hasPrefix("voiceMemo_") {
            let components = nameWithoutExt.split(separator: "_")
            if components.count >= 2,
               let timestamp = Double(components[1]) {
                let date = Date(timeIntervalSince1970: timestamp)
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return "Voice Memo - \(formatter.string(from: date))"
            }
        }
        
        return nameWithoutExt
    }
    
    private func indexCalendarEvents() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let allEvents = CalendarManager.shared.getAllEvents()
        
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { $0.count > 3 }
            .map { $0.lowercased() }
            .prefix(10)
            .map { String($0) }
    }
}