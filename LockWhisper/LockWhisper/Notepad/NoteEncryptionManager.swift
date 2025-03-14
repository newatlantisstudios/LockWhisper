import CryptoKit
import Foundation

enum NoteCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

class NoteEncryptionManager {
    static let shared = NoteEncryptionManager()
    
    private let keychainManager = NoteKeychainManager()
    private let keychainId = "com.lockwhisper.notepad.encryptionKey"
    
    // Get or create a symmetric encryption key
    func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let key = try getEncryptionKey() {
            return key
        }
        
        // Generate and save a new key
        let newKey = SymmetricKey(size: .bits256)
        try saveEncryptionKey(newKey)
        return newKey
    }
    
    private func getEncryptionKey() throws -> SymmetricKey? {
        guard let keyData = try keychainManager.get(account: keychainId) else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveEncryptionKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        try keychainManager.save(account: keychainId, data: keyData)
    }
    
    // Encrypt data
    func encryptData(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        
        // Version marker (1 byte)
        var encryptedData = Data([0x01])
        
        // Generate a nonce
        let nonce = try AES.GCM.Nonce()
        
        // Encrypt data
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        guard let combined = sealedBox.combined else {
            throw NoteCryptoError.encryptionFailed
        }
        
        // Append encrypted data to version marker
        encryptedData.append(combined)
        
        return encryptedData
    }
    
    // Decrypt data
    func decryptData(_ encryptedData: Data) throws -> Data {
        guard encryptedData.count > 1 else {
            throw NoteCryptoError.invalidData
        }
        
        // Check version
        let version = encryptedData[0]
        guard version == 0x01 else {
            throw NoteCryptoError.unsupportedVersion(version)
        }
        
        // Get encryption key
        let key = try getOrCreateEncryptionKey()
        
        // Extract encrypted data (everything after version byte)
        let sealedBoxData = encryptedData.subdata(in: 1..<encryptedData.count)
        
        // Create sealed box and decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // Check if data is encrypted with our method
    func isEncryptedData(_ data: Data) -> Bool {
        // Check for version marker that identifies encrypted data
        return data.count > 0 && data[0] == 0x01  // Version 1
    }
    
    // Encrypt a string
    func encryptString(_ string: String) throws -> Data {
        let data = Data(string.utf8)
        return try encryptData(data)
    }
    
    // Decrypt to string
    func decryptToString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decryptData(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw NoteCryptoError.decryptionFailed
        }
        return string
    }
    
    // Encrypt a string and return as Base64
    func encryptStringToBase64(_ string: String) throws -> String {
        let encryptedData = try encryptString(string)
        return encryptedData.base64EncodedString()
    }
    
    // Decrypt from Base64 to string
    func decryptBase64ToString(_ base64String: String) throws -> String {
        guard let data = Data(base64Encoded: base64String) else {
            throw NoteCryptoError.invalidData
        }
        return try decryptToString(data)
    }
    
    // Check if a string is an encrypted base64 string
    func isEncryptedBase64String(_ base64String: String) -> Bool {
        guard let data = Data(base64Encoded: base64String) else {
            return false
        }
        return isEncryptedData(data)
    }
}

// Keychain Manager for Notes
struct NoteKeychainManager {
    private let service = "com.lockwhisper.notepad"
    
    func save(account: String, data: Data) throws {
        // Delete any existing item first
        try? delete(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NoteKeychainError.unhandledError(status: status)
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
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw NoteKeychainError.unhandledError(status: status)
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
            throw NoteKeychainError.unhandledError(status: status)
        }
    }
    
    enum NoteKeychainError: Error {
        case unhandledError(status: OSStatus)
    }
}
