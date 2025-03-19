import Foundation
import CommonCrypto

class TODOEncryptionManager {
    static let shared = TODOEncryptionManager()
    
    private init() {}
    
    // Check if a string is an encrypted Base64 string
    func isEncryptedBase64String(_ string: String) -> Bool {
        let base64Regex = "^[A-Za-z0-9+/]*={0,2}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", base64Regex)
        return predicate.evaluate(with: string) && string.count >= 16 // Minimum length check
    }
    
    // Encrypt a string and return the result as a Base64 encoded string
    func encryptStringToBase64(_ string: String) throws -> String {
        // Convert string to data
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "TODOEncryptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
        
        // Create key data
        let key = "lockwhisper12345"
        guard let keyData = key.data(using: .utf8) else {
            throw NSError(domain: "TODOEncryptionError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create key"])
        }
        
        // Create initialization vector (IV)
        let ivSize = kCCBlockSizeAES128
        var ivBytes = [UInt8](repeating: 0, count: ivSize)
        let status = SecRandomCopyBytes(kSecRandomDefault, ivSize, &ivBytes)
        if status != errSecSuccess {
            throw NSError(domain: "TODOEncryptionError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create IV"])
        }
        let iv = Data(ivBytes)
        
        // Prepare for encryption
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var outputBytes = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted = 0
        
        // Get pointers to data
        let keyBytes = (keyData as NSData).bytes
        let dataBytes = (data as NSData).bytes
        let ivPointer = (iv as NSData).bytes
        
        // Perform encryption
        let cryptStatus = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes, min(keyData.count, kCCKeySizeAES256),
            ivPointer,
            dataBytes, dataLength,
            &outputBytes, bufferSize,
            &numBytesEncrypted
        )
        
        if cryptStatus != CCCryptorStatus(kCCSuccess) {
            throw NSError(domain: "TODOEncryptionError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Encryption failed with status \(cryptStatus)"])
        }
        
        // Create encrypted data
        let encryptedData = Data(bytes: outputBytes, count: numBytesEncrypted)
        let finalData = iv + encryptedData
        
        // Return as Base64 encoded string
        return finalData.base64EncodedString()
    }
    
    // Decrypt a Base64 encoded string
    func decryptBase64ToString(_ base64String: String) throws -> String {
        // Decode Base64 string
        guard let data = Data(base64Encoded: base64String) else {
            throw NSError(domain: "TODOEncryptionError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to decode Base64 string"])
        }
        
        // Extract IV and encrypted data
        let ivSize = kCCBlockSizeAES128
        guard data.count > ivSize else {
            throw NSError(domain: "TODOEncryptionError", code: 9, userInfo: [NSLocalizedDescriptionKey: "Data too small to contain IV"])
        }
        
        let iv = data.prefix(ivSize)
        let encryptedData = data.suffix(from: ivSize)
        
        // Create key data
        let key = "lockwhisper12345"
        guard let keyData = key.data(using: .utf8) else {
            throw NSError(domain: "TODOEncryptionError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to create key"])
        }
        
        // Prepare for decryption
        let dataLength = encryptedData.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var outputBytes = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted = 0
        
        // Get pointers to data
        let keyBytes = (keyData as NSData).bytes
        let encryptedBytes = (encryptedData as NSData).bytes
        let ivPointer = (iv as NSData).bytes
        
        // Perform decryption
        let cryptStatus = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes, min(keyData.count, kCCKeySizeAES256),
            ivPointer,
            encryptedBytes, dataLength,
            &outputBytes, bufferSize,
            &numBytesDecrypted
        )
        
        if cryptStatus != CCCryptorStatus(kCCSuccess) {
            throw NSError(domain: "TODOEncryptionError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Decryption failed with status \(cryptStatus)"])
        }
        
        // Create decrypted data
        let decryptedData = Data(bytes: outputBytes, count: numBytesDecrypted)
        
        // Convert to string
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw NSError(domain: "TODOEncryptionError", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to convert decrypted data to string"])
        }
        
        return decryptedString
    }
}
