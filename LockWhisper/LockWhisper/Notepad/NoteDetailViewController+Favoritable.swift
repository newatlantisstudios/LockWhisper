import UIKit
import CoreData

// Simple extension to make Note conform to Favoritable
extension Note: Favoritable {
    var favoriteId: String {
        return objectID.uriRepresentation().absoluteString
    }
    
    var favoriteDisplayName: String {
        // Access text property safely - it's declared in Note+CoreDataProperties.swift
        let storedText = self.text ?? ""
        
        // Decrypt the text if it's encrypted
        if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
            do {
                let decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                return String(decryptedText.prefix(20)).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                // Use the first part of the note as fallback if decryption fails
                return "Note" 
            }
        } else {
            // For unencrypted notes, just trim the text
            return String(storedText.prefix(20)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    var favoriteModuleName: String {
        return ModuleType.notes
    }
    
    var favoriteIconName: String? {
        return "notepad"
    }
}

// Extension to add favorite functionality to NoteDetailViewController
extension NoteDetailViewController {
    
    // Call this method in viewDidLoad to set up favorite button
    func setupFavoriteButton() {
        // Create favorite button
        updateFavoriteButton()
        
        // Add to navigation bar
        let saveButton = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItems = [saveButton!, favoriteBarButton]
    }
    
    // Update favorite button appearance based on current state
    func updateFavoriteButton() {
        let isFavorite = FavoritesManager.shared.isFavorite(
            id: note.favoriteId,
            moduleType: note.favoriteModuleName
        )
        
        let icon = isFavorite ? "star.fill" : "star"
        favoriteBarButton = UIBarButtonItem(
            image: UIImage(systemName: icon),
            style: .plain,
            target: self,
            action: #selector(favoriteButtonTapped)
        )
        favoriteBarButton.tintColor = isFavorite ? .systemYellow : nil
        
        // Update navigation items if they're already set
        if navigationItem.rightBarButtonItems != nil && navigationItem.rightBarButtonItems!.count > 1 {
            navigationItem.rightBarButtonItems![1] = favoriteBarButton
        }
    }
    
    // Handle favorite button tap
    @objc func favoriteButtonTapped() {
        // Toggle favorite status
        FavoritesManager.shared.toggleFavorite(item: note)
        
        // Update UI
        updateFavoriteButton()
    }
}