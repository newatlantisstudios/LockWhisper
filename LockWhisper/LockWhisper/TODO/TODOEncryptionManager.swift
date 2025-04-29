import Foundation
import CryptoKit

class TODOKeychainManager: KeychainManager {
    private let service = "com.lockwhisper.todo"
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
            throw NSError(domain: "TODOKeychainError", code: Int(status), userInfo: nil)
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
            throw NSError(domain: "TODOKeychainError", code: Int(status), userInfo: nil)
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
            throw NSError(domain: "TODOKeychainError", code: Int(status), userInfo: nil)
        }
    }
}

typealias TODOEncryptionManager = SymmetricEncryptionManager<TODOKeychainManager>

extension TODOEncryptionManager {
    static let shared = TODOEncryptionManager(keychainManager: TODOKeychainManager(), keychainId: "com.lockwhisper.todo.encryptionKey")
}
