import Foundation
import CryptoKit

// Simple KeychainManager implementation for search
class SearchKeychainManager: KeychainManager {
    let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func save(account: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainError.unableToSave
            }
        } else if status != errSecSuccess {
            throw KeychainError.unableToSave
        }
    }
    
    func get(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.unableToLoad
        }
    }
    
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unableToDelete
        }
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToLoad
    case unableToDelete
}

class SearchIndexManager {
    static let shared = SearchIndexManager()
    
    private let encryptionManager: SymmetricEncryptionManager<SearchKeychainManager>
    private let keychainService = Constants.searchService
    private let keychainKey = Constants.searchIndexKeychainKey
    
    private var searchIndex: [SearchIndexEntry] = []
    private let indexQueue = DispatchQueue(label: "com.lockwhisper.search.index", attributes: .concurrent)
    
    private init() {
        let keychainManager = SearchKeychainManager(service: keychainService)
        self.encryptionManager = SymmetricEncryptionManager(
            keychainManager: keychainManager,
            keychainId: keychainKey
        )
        loadIndex()
    }
    
    // MARK: - Index Management
    
    func loadIndex() {
        indexQueue.sync {
            guard let data = UserDefaults.standard.data(forKey: Constants.searchIndexDataKey),
                  let decryptedData = try? encryptionManager.decryptData(data) else {
                return
            }
            
            searchIndex = (try? JSONDecoder().decode([SearchIndexEntry].self, from: decryptedData)) ?? []
        }
    }
    
    func saveIndex() {
        indexQueue.async(flags: .barrier) {
            guard let data = try? JSONEncoder().encode(self.searchIndex),
                  let encryptedData = try? self.encryptionManager.encryptData(data) else {
                return
            }
            
            UserDefaults.standard.set(encryptedData, forKey: Constants.searchIndexDataKey)
            UserDefaults.standard.set(Date(), forKey: Constants.searchIndexLastUpdateKey)
        }
    }
    
    // MARK: - Indexing
    
    func addToIndex(_ entry: SearchIndexEntry) {
        indexQueue.async(flags: .barrier) {
            // Remove existing entry with same ID
            self.searchIndex.removeAll { $0.id == entry.id }
            self.searchIndex.append(entry)
            self.saveIndex()
        }
    }
    
    func removeFromIndex(id: String) {
        indexQueue.async(flags: .barrier) {
            self.searchIndex.removeAll { $0.id == id }
            self.saveIndex()
        }
    }
    
    func updateIndex(_ entries: [SearchIndexEntry]) {
        indexQueue.async(flags: .barrier) {
            for entry in entries {
                self.searchIndex.removeAll { $0.id == entry.id }
                self.searchIndex.append(entry)
            }
            self.saveIndex()
        }
    }
    
    func clearIndex() {
        indexQueue.async(flags: .barrier) {
            self.searchIndex.removeAll()
            self.saveIndex()
        }
    }
    
    // MARK: - Searching
    
    func search(query: String, filter: SearchFilter = .all) -> [SearchResult] {
        return indexQueue.sync {
            let searchTerms = query.lowercased().split(separator: " ").map { String($0) }
            
            var results: [SearchResult] = []
            
            for entry in searchIndex {
                // Type filter
                if let types = filter.types {
                    guard let entryType = SearchResultType.from(string: entry.type),
                          types.contains(entryType) else {
                        continue
                    }
                }
                
                // Date filter
                if let dateFrom = filter.dateFrom, entry.timestamp < dateFrom {
                    continue
                }
                if let dateTo = filter.dateTo, entry.timestamp > dateTo {
                    continue
                }
                
                // Calculate relevance score
                var score = 0.0
                _ = (entry.title + " " + entry.content + " " + entry.keywords.joined(separator: " ")).lowercased()
                
                for term in searchTerms {
                    if entry.title.lowercased().contains(term) {
                        score += 3.0
                    }
                    if entry.content.lowercased().contains(term) {
                        score += 1.0
                    }
                    for keyword in entry.keywords {
                        if keyword.lowercased().contains(term) {
                            score += 2.0
                        }
                    }
                }
                
                if score > 0, let result = entry.toSearchResult(relevanceScore: score) {
                    results.append(result)
                }
            }
            
            // Sort by relevance and recency
            return results.sorted { $0.sortValue > $1.sortValue }
        }
    }
    
    // MARK: - Recent Searches
    
    func getRecentSearches() -> [String] {
        return UserDefaults.standard.stringArray(forKey: Constants.recentSearchesKey) ?? []
    }
    
    func addRecentSearch(_ query: String) {
        var recentSearches = getRecentSearches()
        
        // Remove if already exists
        recentSearches.removeAll { $0 == query }
        
        // Add to beginning
        recentSearches.insert(query, at: 0)
        
        // Limit to max recent searches
        if recentSearches.count > Constants.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Constants.maxRecentSearches))
        }
        
        UserDefaults.standard.set(recentSearches, forKey: Constants.recentSearchesKey)
    }
    
    func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: Constants.recentSearchesKey)
    }
}