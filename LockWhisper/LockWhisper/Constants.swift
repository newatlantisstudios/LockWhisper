import Foundation

/// Centralized constants for keys, entity names, and other hardcoded values.
struct Constants {
    // UserDefaults Keys
    static let biometricEnabled = "biometricEnabled"
    static let publicPGPKey = "publicPGPKey"
    static let savedContacts = "savedContacts"
    static let savedPasswords = "savedPasswords"
    static let allowUnencryptedFallback = "allowUnencryptedFallback"
    static let biometricCheckInterval = "biometricCheckInterval"
    static let lastBiometricAuthTime = "lastBiometricAuthTime"
    static let failedUnlockAttempts = "failedUnlockAttempts"
    static let autoDestructLocked = "autoDestructLocked"
    static let maxFailedAttempts = "maxFailedAttempts" // Key for configurable max failed attempts
    static let defaultMaxFailedAttempts = 5 // Default value if not configured
    static let autoDestructEnabled = "autoDestructEnabled"
    static let autoDestructToggleTimer = 30 // Seconds to wait before toggle takes effect

    // Keychain Keys
    static let privatePGPKey = "privatePGPKey"
    static let contactsEncryptionKey = "com.lockwhisper.contacts.encryptionKey"
    static let notepadEncryptionKey = "com.lockwhisper.notepad.encryptionKey"
    static let passwordsEncryptionKey = "com.lockwhisper.passwords.encryptionKey"
    static let pgpEncryptionKey = "com.lockwhisper.pgp.encryptionKey"
    static let todoEncryptionKey = "com.lockwhisper.todo.encryptionKey"
    static let fileVaultEncryptionKey = "com.lockwhisper.filevault.encryptionKey"

    // Keychain Services
    static let contactsService = "com.lockwhisper.contacts"
    static let notepadService = "com.lockwhisper.notepad"
    static let passwordsService = "com.lockwhisper.passwords"
    static let pgpService = "com.lockwhisper.pgp"
    static let todoService = "com.lockwhisper.todo"
    static let fileVaultService = "com.lockwhisper.filevault"

    // CoreData Entity Names
    static let noteEntity = "Note"
    static let todoItemEntity = "TODOItem"

    // Migration
    static let migrationDomain = "com.lockwhisper.migration"

    // File Names
    static let notesDecryptedFile = "notes_decrypted.json"
    static let keychainItemsFile = "keychain_items.json"
    static let userDefaultsDecryptedFile = "user_defaults_decrypted.json"
    
    // Remote Wipe
    static let remoteWipeEnabled = "remoteWipeEnabled"
    
    // Recovery Mechanism
    static let recoveryEnabled = "recoveryEnabled"
    static let recoveryTimeWindow = "recoveryTimeWindow"
    static let recoveryPINHash = "recoveryPINHash"
    static let encryptedPGPConversations = "encryptedPGPConversations"
    static let encryptedPasswordsKey = "encryptedPasswordsKey"
    static let encryptedContactsKey = "encryptedContactsKey"
    static let remoteWipePIN = "remoteWipePIN"
    static let remoteWipeAttempts = "remoteWipeAttempts"
    
    // Fake Password System
    static let fakePasswordEnabled = "fakePasswordEnabled"
    static let fakePasswordService = "com.lockwhisper.fakepassword"
    static let fakePasswordAccount = "fakePasswordHash"
    static let realPasswordService = "com.lockwhisper.realpassword"
    static let realPasswordAccount = "realPasswordHash"
    
    // Search
    static let searchIndexKeychainKey = "com.lockwhisper.search.indexKey"
    static let searchService = "com.lockwhisper.search"
    static let recentSearchesKey = "recentSearches"
    static let searchIndexDataKey = "searchIndexData"
    static let searchIndexLastUpdateKey = "searchIndexLastUpdate"
    static let maxRecentSearches = 10
}
