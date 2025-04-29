import Foundation
import CryptoKit

// MARK: - KeychainManager Protocol

public protocol KeychainManager {
    func save(account: String, data: Data) throws
    func get(account: String) throws -> Data?
    func delete(account: String) throws
}

// MARK: - SymmetricEncryptionManager

public class SymmetricEncryptionManager<KM: KeychainManager> {
    public let keychainManager: KM
    public let keychainId: String

    public init(keychainManager: KM, keychainId: String) {
        self.keychainManager = keychainManager
        self.keychainId = keychainId
    }

    // Get or create a symmetric encryption key
    public func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let key = try getEncryptionKey() {
            return key
        }
        let newKey = SymmetricKey(size: .bits256)
        try saveEncryptionKey(newKey)
        return newKey
    }

    public func getEncryptionKey() throws -> SymmetricKey? {
        guard let keyData = try keychainManager.get(account: keychainId) else {
            return nil
        }
        return SymmetricKey(data: keyData)
    }

    public func saveEncryptionKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        try keychainManager.save(account: keychainId, data: keyData)
    }

    // Encrypt data
    public func encryptData(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        var encryptedData = Data([0x01]) // Version marker
        let nonce = try AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        guard let combined = sealedBox.combined else {
            throw NSError(domain: "SymmetricEncryptionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Encryption failed"])
        }
        encryptedData.append(combined)
        return encryptedData
    }

    // Decrypt data
    public func decryptData(_ encryptedData: Data) throws -> Data {
        guard encryptedData.count > 1 else {
            throw NSError(domain: "SymmetricEncryptionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Data too small to decrypt"])
        }
        let version = encryptedData[0]
        guard version == 0x01 else {
            throw NSError(domain: "SymmetricEncryptionManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unsupported version"])
        }
        let key = try getOrCreateEncryptionKey()
        let sealedBoxData = encryptedData.subdata(in: 1..<encryptedData.count)
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // Check if data is encrypted with our method
    public func isEncryptedData(_ data: Data) -> Bool {
        return data.count > 0 && data[0] == 0x01
    }

    // Encrypt a string
    public func encryptString(_ string: String) throws -> Data {
        let data = Data(string.utf8)
        return try encryptData(data)
    }

    // Decrypt to string
    public func decryptToString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decryptData(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw NSError(domain: "SymmetricEncryptionManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to convert decrypted data to string"])
        }
        return string
    }

    // Encrypt a string and return as Base64
    public func encryptStringToBase64(_ string: String) throws -> String {
        let encryptedData = try encryptString(string)
        return encryptedData.base64EncodedString()
    }

    // Decrypt from Base64 to string
    public func decryptBase64ToString(_ base64String: String) throws -> String {
        guard let data = Data(base64Encoded: base64String) else {
            throw NSError(domain: "SymmetricEncryptionManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Base64 string"])
        }
        return try decryptToString(data)
    }

    // Check if a string is an encrypted base64 string
    public func isEncryptedBase64String(_ base64String: String) -> Bool {
        guard let data = Data(base64Encoded: base64String) else {
            return false
        }
        return isEncryptedData(data)
    }
} 