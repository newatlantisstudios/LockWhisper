import CryptoKit
import Foundation

enum PasswordCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

struct PasswordKeychainManager: KeychainManager {
    private let service = "com.lockwhisper.passwords"
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
            throw PasswordKeychainError.unhandledError(status: status)
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
            throw PasswordKeychainError.unhandledError(status: status)
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
            throw PasswordKeychainError.unhandledError(status: status)
        }
    }
    enum PasswordKeychainError: Error {
        case unhandledError(status: OSStatus)
    }
}

typealias PasswordEncryptionManager = SymmetricEncryptionManager<PasswordKeychainManager>

extension PasswordEncryptionManager {
    static let shared = PasswordEncryptionManager(keychainManager: PasswordKeychainManager(), keychainId: "com.lockwhisper.passwords.encryptionKey")
}
