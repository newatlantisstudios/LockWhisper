import Foundation
import CryptoKit
import LocalAuthentication
import CoreData

// MARK: - Recovery Keychain Manager

struct RecoveryKeychainManager: KeychainManager {
    private let service = "com.lockwhisper.recovery"
    
    func save(account: String, data: Data) throws {
        try? delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw RecoveryKeychainError.unhandledError(status: status)
        }
    }
    
    func get(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw RecoveryKeychainError.unhandledError(status: status)
        }
        return result as? Data
    }
    
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw RecoveryKeychainError.unhandledError(status: status)
        }
    }
}

enum RecoveryKeychainError: Error {
    case unhandledError(status: OSStatus)
}

/// Manager responsible for data recovery mechanisms
class RecoveryManager {
    static let shared = RecoveryManager()
    
    private let keychainManager = RecoveryKeychainManager()
    private let recoveryKeyIdentifier = "com.lockwhisper.recovery.key"
    private let recoveryBackupIdentifier = "com.lockwhisper.recovery.backup"
    private let recoveryPINIdentifier = "com.lockwhisper.recovery.pin"
    
    private init() {}
    
    // MARK: - Recovery Configuration
    
    /// Check if recovery is enabled
    var isRecoveryEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.recoveryEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.recoveryEnabled)
        }
    }
    
    /// Recovery time window in seconds (default 24 hours)
    var recoveryTimeWindow: TimeInterval {
        get {
            let saved = UserDefaults.standard.double(forKey: Constants.recoveryTimeWindow)
            return saved > 0 ? saved : 86400 // 24 hours default
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.recoveryTimeWindow)
        }
    }
    
    // MARK: - Recovery Key Generation
    
    /// Generate recovery key for backup
    func generateRecoveryKey() throws -> String {
        // Generate 32-byte recovery key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Store in keychain for recovery
        try keychainManager.save(account: recoveryKeyIdentifier, data: keyData)
        
        // Convert to readable format (base64)
        return keyData.base64EncodedString()
    }
    
    /// Generate recovery PIN (6-digit)
    func generateRecoveryPIN() -> String {
        let pin = String(format: "%06d", arc4random_uniform(1000000))
        
        // Hash the PIN for storage
        if let pinData = pin.data(using: .utf8) {
            let hashedPIN = SHA256.hash(data: pinData)
            let hashString = hashedPIN.compactMap { String(format: "%02x", $0) }.joined()
            
            // Store hashed PIN
            UserDefaults.standard.set(hashString, forKey: Constants.recoveryPINHash)
        }
        
        return pin
    }
    
    // MARK: - Pre-destruction Backup
    
    /// Create encrypted backup before auto-destruct
    func createPreDestructionBackup() throws -> Data {
        guard isRecoveryEnabled else {
            throw RecoveryError.recoveryDisabled
        }
        
        // Collect all data to backup
        var backupData: [String: Any] = [:]
        
        // Backup notes
        backupData["notes"] = try backupNotes()
        
        // Backup passwords
        backupData["passwords"] = try backupPasswords()
        
        // Backup contacts
        backupData["contacts"] = try backupContacts()
        
        // Backup TODO items
        backupData["todos"] = try backupTODOs()
        
        // Backup PGP conversations
        backupData["pgpConversations"] = try backupPGPConversations()
        
        // Add timestamp
        backupData["timestamp"] = Date().timeIntervalSince1970
        backupData["expiresAt"] = Date().addingTimeInterval(recoveryTimeWindow).timeIntervalSince1970
        
        // Serialize backup data
        let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
        
        // Encrypt backup with recovery key
        guard let recoveryKey = try keychainManager.get(account: recoveryKeyIdentifier) else {
            throw RecoveryError.invalidRecoveryKey
        }
        let encryptedBackup = try encryptBackup(jsonData, with: recoveryKey)
        
        // Store encrypted backup
        try storeBackup(encryptedBackup)
        
        return encryptedBackup
    }
    
    // MARK: - Recovery Process
    
    /// Verify recovery PIN
    func verifyRecoveryPIN(_ pin: String) -> Bool {
        guard let pinData = pin.data(using: .utf8),
              let storedHash = UserDefaults.standard.string(forKey: Constants.recoveryPINHash) else {
            return false
        }
        
        let hashedPIN = SHA256.hash(data: pinData)
        let hashString = hashedPIN.compactMap { String(format: "%02x", $0) }.joined()
        
        return hashString == storedHash
    }
    
    /// Recover data with recovery key
    func recoverData(with recoveryKey: String) throws {
        // Verify biometric authentication first
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw RecoveryError.biometricAuthenticationRequired
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var authSuccess = false
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                               localizedReason: "Authenticate to recover data") { success, error in
            authSuccess = success
            semaphore.signal()
        }
        
        semaphore.wait()
        
        guard authSuccess else {
            throw RecoveryError.authenticationFailed
        }
        
        // Decode recovery key
        guard let keyData = Data(base64Encoded: recoveryKey) else {
            throw RecoveryError.invalidRecoveryKey
        }
        
        // Retrieve encrypted backup
        guard let encryptedBackup = try? retrieveBackup() else {
            throw RecoveryError.backupNotFound
        }
        
        // Check if backup is not expired
        let backupTimestamp = try getBackupTimestamp(encryptedBackup, with: keyData)
        if Date().timeIntervalSince1970 > backupTimestamp + recoveryTimeWindow {
            throw RecoveryError.backupExpired
        }
        
        // Decrypt backup
        let decryptedData = try decryptBackup(encryptedBackup, with: keyData)
        
        // Restore data
        try restoreData(from: decryptedData)
        
        // Clear backup after successful recovery
        clearBackup()
    }
    
    // MARK: - Private Helper Methods
    
    private func encryptBackup(_ data: Data, with key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealed = try AES.GCM.seal(data, using: symmetricKey)
        
        guard let combined = sealed.combined else {
            throw RecoveryError.encryptionFailed
        }
        
        return combined
    }
    
    private func decryptBackup(_ data: Data, with key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    private func storeBackup(_ data: Data) throws {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsDirectory.appendingPathComponent("recovery_backup.encrypted")
        try data.write(to: backupURL)
    }
    
    private func retrieveBackup() throws -> Data {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsDirectory.appendingPathComponent("recovery_backup.encrypted")
        return try Data(contentsOf: backupURL)
    }
    
    private func clearBackup() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsDirectory.appendingPathComponent("recovery_backup.encrypted")
        try? FileManager.default.removeItem(at: backupURL)
    }
    
    private func getBackupTimestamp(_ encryptedData: Data, with key: Data) throws -> TimeInterval {
        let decryptedData = try decryptBackup(encryptedData, with: key)
        let json = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any]
        guard let timestamp = json?["timestamp"] as? TimeInterval else {
            throw RecoveryError.invalidBackupFormat
        }
        return timestamp
    }
    
    // MARK: - Data Backup Methods
    
    private func backupNotes() throws -> [[String: Any]] {
        let context = CoreDataManager.shared.context
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.noteEntity)
        let notes = try context.fetch(fetchRequest)
        
        return notes.compactMap { note in
            guard let title = note.value(forKey: "title") as? String,
                  let content = note.value(forKey: "content") as? String,
                  let date = note.value(forKey: "date") as? Date else {
                return nil
            }
            
            return [
                "title": title,
                "content": content,
                "date": date.timeIntervalSince1970
            ]
        }
    }
    
    private func backupPasswords() throws -> [[String: Any]] {
        guard let passwordsData = UserDefaults.standard.data(forKey: Constants.encryptedPasswordsKey),
              let passwords = try? JSONSerialization.jsonObject(with: passwordsData) as? [[String: Any]] else {
            return []
        }
        return passwords
    }
    
    private func backupContacts() throws -> [[String: Any]] {
        guard let contactsData = UserDefaults.standard.data(forKey: Constants.encryptedContactsKey),
              let contacts = try? JSONSerialization.jsonObject(with: contactsData) as? [[String: Any]] else {
            return []
        }
        return contacts
    }
    
    private func backupTODOs() throws -> [[String: Any]] {
        let context = CoreDataManager.shared.context
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Constants.todoItemEntity)
        let todos = try context.fetch(fetchRequest)
        
        return todos.compactMap { todo in
            guard let title = todo.value(forKey: "title") as? String,
                  let isCompleted = todo.value(forKey: "isCompleted") as? Bool,
                  let date = todo.value(forKey: "dateCreated") as? Date else {
                return nil
            }
            
            return [
                "title": title,
                "isCompleted": isCompleted,
                "dateCreated": date.timeIntervalSince1970
            ]
        }
    }
    
    private func backupPGPConversations() throws -> [[String: Any]] {
        guard let conversationsData = UserDefaults.standard.data(forKey: Constants.encryptedPGPConversations),
              let conversations = try? JSONSerialization.jsonObject(with: conversationsData) as? [[String: Any]] else {
            return []
        }
        return conversations
    }
    
    // MARK: - Data Restoration Methods
    
    private func restoreData(from decryptedData: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any] else {
            throw RecoveryError.invalidBackupFormat
        }
        
        // Restore notes
        if let notes = json["notes"] as? [[String: Any]] {
            try restoreNotes(notes)
        }
        
        // Restore passwords
        if let passwords = json["passwords"] as? [[String: Any]] {
            try restorePasswords(passwords)
        }
        
        // Restore contacts
        if let contacts = json["contacts"] as? [[String: Any]] {
            try restoreContacts(contacts)
        }
        
        // Restore TODOs
        if let todos = json["todos"] as? [[String: Any]] {
            try restoreTODOs(todos)
        }
        
        // Restore PGP conversations
        if let conversations = json["pgpConversations"] as? [[String: Any]] {
            try restorePGPConversations(conversations)
        }
    }
    
    private func restoreNotes(_ notes: [[String: Any]]) throws {
        let context = CoreDataManager.shared.context
        
        for noteData in notes {
            let note = NSEntityDescription.insertNewObject(forEntityName: Constants.noteEntity, into: context)
            note.setValue(noteData["title"], forKey: "title")
            note.setValue(noteData["content"], forKey: "content")
            
            if let timestamp = noteData["date"] as? TimeInterval {
                note.setValue(Date(timeIntervalSince1970: timestamp), forKey: "date")
            }
        }
        
        try context.save()
    }
    
    private func restorePasswords(_ passwords: [[String: Any]]) throws {
        let passwordsData = try JSONSerialization.data(withJSONObject: passwords)
        UserDefaults.standard.set(passwordsData, forKey: Constants.encryptedPasswordsKey)
    }
    
    private func restoreContacts(_ contacts: [[String: Any]]) throws {
        let contactsData = try JSONSerialization.data(withJSONObject: contacts)
        UserDefaults.standard.set(contactsData, forKey: Constants.encryptedContactsKey)
    }
    
    private func restoreTODOs(_ todos: [[String: Any]]) throws {
        let context = CoreDataManager.shared.context
        
        for todoData in todos {
            let todo = NSEntityDescription.insertNewObject(forEntityName: Constants.todoItemEntity, into: context)
            todo.setValue(todoData["title"], forKey: "title")
            todo.setValue(todoData["isCompleted"], forKey: "isCompleted")
            
            if let timestamp = todoData["dateCreated"] as? TimeInterval {
                todo.setValue(Date(timeIntervalSince1970: timestamp), forKey: "dateCreated")
            }
        }
        
        try context.save()
    }
    
    private func restorePGPConversations(_ conversations: [[String: Any]]) throws {
        let conversationsData = try JSONSerialization.data(withJSONObject: conversations)
        UserDefaults.standard.set(conversationsData, forKey: Constants.encryptedPGPConversations)
    }
}

// MARK: - Recovery Errors

enum RecoveryError: Error {
    case recoveryDisabled
    case invalidRecoveryKey
    case backupNotFound
    case backupExpired
    case encryptionFailed
    case decryptionFailed
    case invalidBackupFormat
    case authenticationFailed
    case biometricAuthenticationRequired
    
    var localizedDescription: String {
        switch self {
        case .recoveryDisabled:
            return "Recovery mechanism is not enabled"
        case .invalidRecoveryKey:
            return "Invalid recovery key provided"
        case .backupNotFound:
            return "No recovery backup found"
        case .backupExpired:
            return "Recovery backup has expired"
        case .encryptionFailed:
            return "Failed to encrypt backup data"
        case .decryptionFailed:
            return "Failed to decrypt backup data"
        case .invalidBackupFormat:
            return "Invalid backup data format"
        case .authenticationFailed:
            return "Authentication failed"
        case .biometricAuthenticationRequired:
            return "Biometric authentication is required"
        }
    }
}