import Foundation
import UIKit

extension MediaLibraryViewController: SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry] {
        var entries: [SearchIndexEntry] = []
        
        // Index voice memos from the media files
        for mediaFile in mediaFiles.filter({ $0.isVoiceMemo }) {
            let fileName = mediaFile.url.lastPathComponent
            let nameWithoutExtension = mediaFile.url.deletingPathExtension().lastPathComponent
            
            // Extract date from filename if available
            let displayName = formatVoiceMemoName(fileName)
            
            let entry = SearchIndexEntry(
                id: mediaFile.url.absoluteString,
                type: .voiceMemo,
                title: displayName,
                content: displayName,
                keywords: [displayName, "voice memo", "audio"],
                timestamp: mediaFile.creationDate
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
    
    // Call this after media files are loaded
    func indexVoiceMemos() {
        updateSearchIndex()
    }
    
    private func formatVoiceMemoName(_ fileName: String) -> String {
        // Remove extension and format the filename
        let nameWithoutExt = fileName.replacingOccurrences(of: ".enc", with: "")
        
        // Extract timestamp if present in format: voiceMemo_timestamp_uuid
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
}