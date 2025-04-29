import CryptoKit
import Foundation

enum NoteCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

struct NoteKeychainManager: KeychainManager {
    private let service = "com.lockwhisper.notepad"
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
        if status == errSecItemNotFound { return nil }
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

typealias NoteEncryptionManager = SymmetricEncryptionManager<NoteKeychainManager>

extension NoteEncryptionManager {
    static let shared = NoteEncryptionManager(keychainManager: NoteKeychainManager(), keychainId: "com.lockwhisper.notepad.encryptionKey")
}
