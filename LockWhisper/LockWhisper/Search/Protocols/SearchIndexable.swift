import Foundation

protocol SearchIndexable {
    func buildSearchIndexEntries() -> [SearchIndexEntry]
    func updateSearchIndex()
    func removeFromSearchIndex(id: String)
}