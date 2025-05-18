import Foundation
import Security
import CryptoKit

/// Manages the fake password system for creating decoy data
class FakePasswordManager {
    static let shared = FakePasswordManager()
    
    private init() {}
    
    /// Current authentication mode
    enum AuthMode {
        case real
        case fake
    }
    
    var currentMode: AuthMode = .real
    
    var isInFakeMode: Bool {
        currentMode == .fake
    }
    
    // MARK: - Password Setup
    
    /// Sets up a fake password in the keychain
    func setupFakePassword(_ password: String) throws {
        // Hash the password before storing
        let hashedPassword = hashPassword(password)
        
        // Store in keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.fakePasswordService,
            kSecAttrAccount as String: Constants.fakePasswordAccount,
            kSecValueData as String: hashedPassword.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item if present
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "FakePasswordManager", code: Int(status), 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to save fake password"])
        }
        
        // Mark fake password as enabled
        UserDefaults.standard.set(true, forKey: Constants.fakePasswordEnabled)
    }
    
    /// Sets up or updates the real password
    func setupRealPassword(_ password: String) throws {
        // Hash the password before storing
        let hashedPassword = hashPassword(password)
        
        // Store in keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.realPasswordService,
            kSecAttrAccount as String: Constants.realPasswordAccount,
            kSecValueData as String: hashedPassword.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item if present
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "FakePasswordManager", code: Int(status), 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to save real password"])
        }
    }
    
    // MARK: - Password Verification
    
    /// Verifies a password and returns whether it's real or fake
    func verifyPassword(_ password: String) -> AuthMode? {
        let hashedPassword = hashPassword(password)
        
        // Check against real password first
        if let realPassword = getStoredPassword(for: Constants.realPasswordService, account: Constants.realPasswordAccount) {
            if realPassword == hashedPassword {
                currentMode = .real
                return .real
            }
        }
        
        // Check against fake password
        if UserDefaults.standard.bool(forKey: Constants.fakePasswordEnabled) {
            if let fakePassword = getStoredPassword(for: Constants.fakePasswordService, account: Constants.fakePasswordAccount) {
                if fakePassword == hashedPassword {
                    currentMode = .fake
                    return .fake
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Data Management
    
    /// Returns the appropriate keychain service based on current mode
    func getKeychainService(for baseService: String) -> String {
        return isInFakeMode ? "\(baseService).fake" : baseService
    }
    
    /// Returns the appropriate encryption key based on current mode
    func getEncryptionKey(for baseKey: String) -> String {
        return isInFakeMode ? "\(baseKey).fake" : baseKey
    }
    
    /// Returns the appropriate UserDefaults key based on current mode
    func getUserDefaultsKey(for baseKey: String) -> String {
        return isInFakeMode ? "\(baseKey).fake" : baseKey
    }
    
    /// Returns the appropriate CoreData store name based on current mode
    func getCoreDataStoreName() -> String {
        return isInFakeMode ? "NotepadModelFake.sqlite" : "NotepadModel.sqlite"
    }
    
    // MARK: - Helper Methods
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func getStoredPassword(for service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess,
           let data = item as? Data,
           let password = String(data: data, encoding: .utf8) {
            return password
        }
        
        return nil
    }
    
    /// Removes the fake password from keychain
    func removeFakePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.fakePasswordService,
            kSecAttrAccount as String: Constants.fakePasswordAccount
        ]
        
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.set(false, forKey: Constants.fakePasswordEnabled)
    }
    
    /// Wipes all fake data
    func wipeFakeData() {
        // Clear fake keychain items
        let fakeServices = [
            Constants.contactsService + ".fake",
            Constants.notepadService + ".fake",
            Constants.passwordsService + ".fake",
            Constants.pgpService + ".fake",
            Constants.todoService + ".fake",
            Constants.fileVaultService + ".fake"
        ]
        
        for service in fakeServices {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            SecItemDelete(query as CFDictionary)
        }
        
        // Clear fake UserDefaults
        let userDefaultsKeys = [
            Constants.savedContacts,
            Constants.savedPasswords,
            Constants.publicPGPKey,
            Constants.encryptedPGPConversations
        ]
        
        for key in userDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: "\(key).fake")
        }
        
        // Delete fake CoreData store
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fakeStoreURL = documentsDirectory.appendingPathComponent("NotepadModelFake.sqlite")
            let fakeStoreURLShm = documentsDirectory.appendingPathComponent("NotepadModelFake.sqlite-shm")
            let fakeStoreURLWal = documentsDirectory.appendingPathComponent("NotepadModelFake.sqlite-wal")
            
            try? FileManager.default.removeItem(at: fakeStoreURL)
            try? FileManager.default.removeItem(at: fakeStoreURLShm)
            try? FileManager.default.removeItem(at: fakeStoreURLWal)
        }
    }
    
    /// Checks if fake password is enabled
    var isFakePasswordEnabled: Bool {
        UserDefaults.standard.bool(forKey: Constants.fakePasswordEnabled)
    }
}