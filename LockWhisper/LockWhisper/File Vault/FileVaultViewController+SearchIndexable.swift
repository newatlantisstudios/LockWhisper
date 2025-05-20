import Foundation
import UIKit

// Don't implement SearchIndexable yet - we need to fix the SearchIndexable protocol first
// This will be implemented in a future update
extension FileVaultViewController {
    func buildFileSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            for (index, fileURL) in fileURLs.enumerated() {
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
                
                // Extract file type from extension
                let fileExtension = fileURL.pathExtension.lowercased()
                let fileType = getFileType(from: fileExtension)
                
                let entry = SearchIndexEntry(
                    id: fileURL.absoluteString,
                    type: .file,
                    title: fileName,
                    content: "\(fileName) \(fileType)",
                    keywords: [fileName, fileExtension, fileType],
                    timestamp: creationDate,
                    metadata: ["fileSize": fileSize, "fileType": fileType]
                )
                entries.append(entry)
            }
        } catch {
            print("Failed to index files: \(error)")
        }
        
        return entries
    }
    
    func updateFileSearchIndex() {
        let entries = buildFileSearchIndexEntries()
        SearchIndexManager.shared.updateIndex(entries)
    }
    
    func removeFileFromSearchIndex(id: String) {
        SearchIndexManager.shared.removeFromIndex(id: id)
    }
    
    // Call this when files are added or removed
    func indexFiles() {
        updateFileSearchIndex()
    }
    
    private func getFileType(from extension: String) -> String {
        switch `extension`.lowercased() {
        case "pdf": return "PDF Document"
        case "doc", "docx": return "Word Document"
        case "txt": return "Text File"
        case "jpg", "jpeg", "png", "gif": return "Image"
        case "mp4", "mov", "avi": return "Video"
        case "mp3", "m4a", "wav": return "Audio"
        case "zip", "rar", "7z": return "Archive"
        default: return "File"
        }
    }
}