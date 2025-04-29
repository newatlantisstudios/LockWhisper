import CryptoKit
import Foundation

enum FileCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

struct FileKeychainManager: KeychainManager {
    private let service = "com.lockwhisper.filevault"
    
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
            throw KeychainError.unhandledError(status: status)
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
            throw KeychainError.unhandledError(status: status)
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
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    enum KeychainError: Error {
        case unhandledError(status: OSStatus)
    }
}

typealias FileEncryptionManager = SymmetricEncryptionManager<FileKeychainManager>

// If needed, add an extension for file encryption/decryption
extension SymmetricEncryptionManager where KM == FileKeychainManager {
    func encryptFile(at sourceURL: URL, to destinationURL: URL) throws {
        let fileData = try Data(contentsOf: sourceURL)
        let encryptedData = try encryptData(fileData)
        try encryptedData.write(to: destinationURL)
    }
    func decryptFile(at encryptedURL: URL, to decryptedURL: URL) throws {
        let encryptedData = try Data(contentsOf: encryptedURL)
        if isEncryptedData(encryptedData) {
            let decryptedData = try decryptData(encryptedData)
            try decryptedData.write(to: decryptedURL)
        } else {
            try FileManager.default.copyItem(at: encryptedURL, to: decryptedURL)
        }
    }
}

extension FileEncryptionManager {
    static let shared = FileEncryptionManager(
        keychainManager: FileKeychainManager(),
        keychainId: "com.lockwhisper.filevault.encryptionKey"
    )
}
