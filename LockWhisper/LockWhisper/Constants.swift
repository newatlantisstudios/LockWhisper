import Foundation

/// Centralized constants for keys, entity names, and other hardcoded values.
struct Constants {
    // UserDefaults Keys
    static let biometricEnabled = "biometricEnabled"
    static let publicPGPKey = "publicPGPKey"
    static let savedContacts = "savedContacts"
    static let savedPasswords = "savedPasswords"
    static let allowUnencryptedFallback = "allowUnencryptedFallback"

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
}
