import Foundation
import UIKit

// Protocol for items that can be favorited
protocol Favoritable {
    var favoriteId: String { get }
    var favoriteDisplayName: String { get }
    var favoriteModuleName: String { get }
    var favoriteIconName: String? { get }
}

// Manager for handling favorites across modules
class FavoritesManager {
    static let shared = FavoritesManager()
    
    // Data structure for favorites
    struct FavoriteItem: Codable {
        let id: String
        let displayName: String
        let moduleName: String
        var iconName: String
    }
    
    private var favorites: [FavoriteItem] = []
    
    private init() {
        loadFavorites()
    }
    
    // Load favorites from UserDefaults
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: Constants.favoritesKey) {
            if let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
                favorites = decoded
            }
        }
    }
    
    // Save favorites to UserDefaults
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: Constants.favoritesKey)
        }
        
        // Post notification that favorites changed
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }
    
    // Check if an item is a favorite
    func isFavorite(id: String, moduleType: String) -> Bool {
        return favorites.contains { $0.id == id && $0.moduleName == moduleType }
    }
    
    // Add an item to favorites
    func addFavorite(item: Favoritable) {
        // Don't add duplicates
        if isFavorite(id: item.favoriteId, moduleType: item.favoriteModuleName) {
            return
        }
        
        // Use default icon for the module if none provided
        let iconName = item.favoriteIconName ?? getDefaultIconForModule(item.favoriteModuleName)
        
        let favoriteItem = FavoriteItem(
            id: item.favoriteId,
            displayName: item.favoriteDisplayName,
            moduleName: item.favoriteModuleName,
            iconName: iconName
        )
        
        favorites.append(favoriteItem)
        saveFavorites()
    }
    
    // Remove an item from favorites
    func removeFavorite(id: String, moduleType: String) {
        favorites.removeAll { $0.id == id && $0.moduleName == moduleType }
        saveFavorites()
    }
    
    // Toggle favorite status
    func toggleFavorite(item: Favoritable) {
        if isFavorite(id: item.favoriteId, moduleType: item.favoriteModuleName) {
            removeFavorite(id: item.favoriteId, moduleType: item.favoriteModuleName)
        } else {
            addFavorite(item: item)
        }
    }
    
    // Get all favorites
    func getAllFavorites() -> [FavoriteItem] {
        return favorites
    }
    
    // Get favorites for a specific module
    func getFavoritesForModule(_ moduleName: String) -> [FavoriteItem] {
        return favorites.filter { $0.moduleName == moduleName }
    }
    
    // Get default icon name for a module
    private func getDefaultIconForModule(_ moduleName: String) -> String {
        switch moduleName {
        case "Notes":
            return "notepad"
        case "Passwords":
            return "passwords"
        case "Calendar":
            return "calendar"
        case "Contacts":
            return "contacts"
        case "PGP":
            return "pgp"
        case "TODO":
            return "todo"
        case "FileVault":
            return "fileVault"
        case "Camera":
            return "camera"
        case "VoiceMemo":
            return "voiceMemo"
        case "MediaLibrary":
            return "mediaLibrary"
        default:
            return "notepad" // Default fallback
        }
    }
}

// Notification name extension
extension Notification.Name {
    static let favoritesDidChange = Notification.Name("com.newatlantis.lockwhisper.favoritesDidChange")
}

// Module type constants
struct ModuleType {
    static let notes = "Notes"
    static let passwords = "Passwords"
    static let calendar = "Calendar"
    static let contacts = "Contacts"
    static let pgp = "PGP"
    static let todo = "TODO"
    static let fileVault = "FileVault"
    static let camera = "Camera"
    static let voiceMemo = "VoiceMemo"
    static let mediaLibrary = "MediaLibrary"
}