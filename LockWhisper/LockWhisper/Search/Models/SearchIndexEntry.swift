import Foundation

struct SearchIndexEntry: Codable {
    let id: String
    let type: String
    let title: String
    let content: String
    let keywords: [String]
    let timestamp: Date
    let metadata: Data?
    
    init(id: String, type: SearchResultType, title: String, content: String, keywords: [String] = [], timestamp: Date = Date(), metadata: [String: Any]? = nil) {
        self.id = id
        self.type = String(describing: type)
        self.title = title
        self.content = content
        self.keywords = keywords
        self.timestamp = timestamp
        if let metadata = metadata {
            self.metadata = try? JSONSerialization.data(withJSONObject: metadata)
        } else {
            self.metadata = nil
        }
    }
    
    func toSearchResult(relevanceScore: Double) -> SearchResult? {
        guard let type = SearchResultType.from(string: self.type) else { return nil }
        
        var metadataDict: [String: Any]?
        if let data = metadata {
            metadataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        
        return SearchResult(
            id: id,
            type: type,
            title: title,
            subtitle: nil,
            preview: String(content.prefix(100)),
            timestamp: timestamp,
            relevanceScore: relevanceScore,
            metadata: metadataDict
        )
    }
}

extension SearchResultType {
    static func from(string: String) -> SearchResultType? {
        switch string {
        case "note": return .note
        case "password": return .password
        case "contact": return .contact
        case "pgpMessage": return .pgpMessage
        case "file": return .file
        case "todo": return .todo
        case "voiceMemo": return .voiceMemo
        case "event": return .event
        default: return nil
        }
    }
}