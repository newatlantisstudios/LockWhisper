//
//  AppDelegate.swift
//  LockWhisper
//
//  Created by x on 12/17/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Perform data migration if updating from pre-V3 to V3
        performDataMigrationIfNeeded()
        
        // Rest of your app initialization
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate {
    // Call this in didFinishLaunchingWithOptions
    func performDataMigrationIfNeeded() {
        let hasRunMigration = UserDefaults.standard.bool(forKey: "v3_migration_completed")
        
        if !hasRunMigration {
            migrateContactsToV3Format()
            migratePublicKeyToEncrypted()
            migratePrivateKeyToEncrypted()
            
            // Mark migration as complete
            UserDefaults.standard.set(true, forKey: "v3_migration_completed")
        }
        
        // Call the existing migration method to ensure contacts are encrypted
        UserDefaults.standard.migrateContactsIfNeeded()
    }
    
    private func migrateContactsToV3Format() {
        // Check if we have old-format contacts data
        guard let oldContactsData = UserDefaults.standard.data(forKey: "contacts") else {
            return // No old data to migrate
        }
        
        // Try to decode using the old Contact format
        guard let oldContacts = try? JSONDecoder().decode([Contact].self, from: oldContactsData) else {
            return // Can't decode old format, might already be in new format
        }
        
        print("Migrating \(oldContacts.count) contacts from old format to V3 format")
        
        // Convert old contacts to new ContactPGP format
        let newContacts: [ContactPGP] = oldContacts.map { oldContact in
            return ContactPGP(
                id: UUID(), // Generate new UUID
                name: oldContact.name,
                publicKey: oldContact.publicKey,
                messages: oldContact.messages,
                messageDates: oldContact.messageDates,
                notes: nil // Initialize with nil notes
            )
        }
        
        // Use the V3 setter which handles encryption
        UserDefaults.standard.contacts = newContacts
        
        print("Migration of contacts to V3 format completed successfully")
    }
    
    private func migratePublicKeyToEncrypted() {
        let userDefaultsKey = "publicPGPKey"
        
        // Check if there's an old unencrypted public key
        guard let savedKey = UserDefaults.standard.string(forKey: userDefaultsKey),
              !savedKey.isEmpty,
              savedKey != "No PGP key found.",
              savedKey.contains("-----BEGIN PGP PUBLIC KEY BLOCK-----") else {
            return // No valid old public key to migrate
        }
        
        if !PGPEncryptionManager.shared.isEncryptedBase64String(savedKey) {
            do {
                // Encrypt the key
                let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(savedKey)
                
                // Save back to UserDefaults
                UserDefaults.standard.set(encryptedKey, forKey: userDefaultsKey)
                print("Successfully migrated public key to encrypted format")
            } catch {
                print("Failed to migrate public key: \(error.localizedDescription)")
                // Keep the unencrypted key, V3 should still be able to read it
            }
        }
    }
    
    private func migratePrivateKeyToEncrypted() {
        let keychainKey = "privatePGPKey"
        
        do {
            // Try to get the old private key
            guard let privateKey = try KeychainHelper.shared.get(key: keychainKey),
                  !privateKey.isEmpty,
                  privateKey != "Enter your private PGP key here",
                  privateKey.contains("-----BEGIN PGP PRIVATE KEY BLOCK-----") else {
                return // No valid private key to migrate
            }
            
            // Check if it's already encrypted
            if !PGPEncryptionManager.shared.isEncryptedBase64String(privateKey) {
                // Encrypt the key
                let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(privateKey)
                
                // Save back to Keychain
                try KeychainHelper.shared.save(key: keychainKey, value: encryptedKey)
                print("Successfully migrated private key to encrypted format")
            }
        } catch {
            print("Failed to migrate private key: \(error.localizedDescription)")
            // The unencrypted key will remain in keychain, V3 should still be able to read it
        }
    }
}

// Define old Contact struct for migration purposes
struct Contact: Codable {
    var name: String
    var publicKey: String
    var messages: [String]
    var messageDates: [String]
}
