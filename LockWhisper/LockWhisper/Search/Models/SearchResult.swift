import Foundation

enum SearchResultType: String {
    case note
    case password
    case contact
    case pgpMessage
    case file
    case todo
    case voiceMemo
    case event
}

struct SearchResult {
    let id: String
    let type: SearchResultType
    let title: String
    let subtitle: String?
    let preview: String?
    let timestamp: Date
    let relevanceScore: Double
    let metadata: [String: Any]?
    
    var sortValue: Double {
        return relevanceScore + (timestamp.timeIntervalSince1970 / 1_000_000_000)
    }
}

struct SearchFilter {
    var types: Set<SearchResultType>?
    var dateFrom: Date?
    var dateTo: Date?
    var keywords: [String]?
    
    static var all: SearchFilter {
        return SearchFilter()
    }
}