import CryptoKit
import Foundation

enum PGPCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

struct PGPKeychainManager: KeychainManager {
    private let service = "com.lockwhisper.pgp"
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
            throw PGPKeychainError.unhandledError(status: status)
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
            throw PGPKeychainError.unhandledError(status: status)
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
            throw PGPKeychainError.unhandledError(status: status)
        }
    }
    enum PGPKeychainError: Error {
        case unhandledError(status: OSStatus)
    }
}

typealias PGPEncryptionManager = SymmetricEncryptionManager<PGPKeychainManager>

// If needed, add an extension for encryptContacts/decryptContacts
extension SymmetricEncryptionManager where KM == PGPKeychainManager {
    func encryptContacts(_ contacts: [ContactPGP]) throws -> Data {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(contacts)
        return try encryptData(encodedData)
    }
    func decryptContacts(_ encryptedData: Data) throws -> [ContactPGP] {
        let decryptedData = try decryptData(encryptedData)
        return try JSONDecoder().decode([ContactPGP].self, from: decryptedData)
    }
}

extension PGPEncryptionManager {
    static let shared = PGPEncryptionManager(
        keychainManager: PGPKeychainManager(),
        keychainId: "com.lockwhisper.pgp.encryptionKey"
    )
}
