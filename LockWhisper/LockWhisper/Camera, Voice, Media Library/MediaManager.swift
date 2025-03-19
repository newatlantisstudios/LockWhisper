import UIKit
import AVFoundation
import CryptoKit
import Security

class MediaManager {
    
    static let shared = MediaManager()
    
    private init() {}
    
    // MARK: - Encryption Key Management
    
    private func getOrCreateEncryptionKey() -> SymmetricKey? {
        if let existingKey = retrieveKeyFromKeychain() {
            return existingKey
        }
        
        // Create a new key
        let newKey = SymmetricKey(size: .bits256)
        
        // Save to keychain
        if saveKeyToKeychain(newKey) {
            return newKey
        }
        
        return nil
    }
    
    private func retrieveKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MediaEncryptionKey",
            kSecAttrService as String: "LockWhisper",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        }
        
        return nil
    }
    
    private func saveKeyToKeychain(_ key: SymmetricKey) -> Bool {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "MediaEncryptionKey",
            kSecAttrService as String: "LockWhisper",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // First try to delete any existing key
        SecItemDelete(query as CFDictionary)
        
        // Add the new key
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Encryption/Decryption Methods
    
    func encryptData(_ data: Data) -> (encryptedData: Data, success: Bool) {
        guard let key = getOrCreateEncryptionKey() else {
            return (Data(), false)
        }
        
        do {
            // Create a secure random nonce
            let nonce = AES.GCM.Nonce()
            
            // Encrypt the data
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            // Combine nonce and ciphertext for storage
            var combinedData = Data()
            combinedData.append(nonce.withUnsafeBytes { Data($0) })
            combinedData.append(sealedBox.ciphertext)
            combinedData.append(sealedBox.tag)
            
            return (combinedData, true)
        } catch {
            print("Encryption error: \(error)")
            return (Data(), false)
        }
    }
    
    func decryptData(_ encryptedData: Data) -> (decryptedData: Data, success: Bool) {
        guard let key = getOrCreateEncryptionKey() else {
            return (Data(), false)
        }
        
        // Encrypted data format: [nonce (12 bytes)][ciphertext][authentication tag (16 bytes)]
        guard encryptedData.count > 28 else {
            print("Encrypted data is too short")
            return (Data(), false)
        }
        
        do {
            // Extract nonce (first 12 bytes)
            let nonceData = encryptedData.prefix(12)
            let nonce = try AES.GCM.Nonce(data: nonceData)
            
            // Extract authentication tag (last 16 bytes)
            let tagData = encryptedData.suffix(16)
            
            // Extract ciphertext (everything between nonce and tag)
            let ciphertextData = encryptedData.dropFirst(12).dropLast(16)
            
            // Create a sealed box
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce,
                                               ciphertext: ciphertextData,
                                               tag: tagData)
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return (decryptedData, true)
        } catch {
            print("Decryption error: \(error)")
            return (Data(), false)
        }
    }
    
    // MARK: - Media Directory Management
    
    var mediaDirectoryURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let mediaDirectory = documentsDirectory.appendingPathComponent("MediaLibrary")
        
        if !FileManager.default.fileExists(atPath: mediaDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating media directory: \(error)")
                return nil
            }
        }
        
        return mediaDirectory
    }
    
    // MARK: - Save Media
    
    func savePhoto(_ image: UIImage, completion: @escaping (Bool, URL?) -> Void) {
        guard let mediaDirectory = mediaDirectoryURL else {
            completion(false, nil)
            return
        }
        
        let filename = UUID().uuidString + ".enc"
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Encrypt the image data
            let (encryptedData, success) = encryptData(imageData)
            
            if success {
                do {
                    try encryptedData.write(to: fileURL)
                    print("Encrypted photo saved to app's media library at: \(fileURL)")
                    completion(true, fileURL)
                } catch {
                    print("Error saving encrypted photo: \(error)")
                    completion(false, nil)
                }
            } else {
                completion(false, nil)
            }
        } else {
            completion(false, nil)
        }
    }
    
    func saveVideo(from sourceURL: URL, completion: @escaping (Bool, URL?) -> Void) {
        guard let mediaDirectory = mediaDirectoryURL else {
            completion(false, nil)
            return
        }
        
        let filename = UUID().uuidString + ".enc"
        let destinationURL = mediaDirectory.appendingPathComponent(filename)
        
        do {
            // Read video data
            let videoData = try Data(contentsOf: sourceURL)
            
            // Encrypt the video data
            let (encryptedData, success) = encryptData(videoData)
            
            if success {
                try encryptedData.write(to: destinationURL)
                print("Encrypted video saved to app's media library at: \(destinationURL)")
                
                // Delete the original temporary file
                try? FileManager.default.removeItem(at: sourceURL)
                
                completion(true, destinationURL)
            } else {
                completion(false, nil)
            }
        } catch {
            print("Error saving encrypted video: \(error)")
            completion(false, nil)
        }
    }
    
    // MARK: - Load Media
    
    func loadAudio(from url: URL, completion: @escaping (URL?) -> Void) {
        do {
            // Read encrypted data
            let encryptedData = try Data(contentsOf: url)
            
            // Decrypt the data
            let (decryptedData, success) = decryptData(encryptedData)
            
            if success {
                // Create a temporary file for playback
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
                
                try decryptedData.write(to: tempURL)
                completion(tempURL)
            } else {
                // If decryption fails, try using the original file (for backwards compatibility)
                completion(url)
            }
        } catch {
            print("Error preparing audio for playback: \(error)")
            completion(nil)
        }
    }
    
    func loadImage(from url: URL) -> UIImage? {
        do {
            // Read encrypted data
            let encryptedData = try Data(contentsOf: url)
            
            // Decrypt the data
            let (decryptedData, success) = decryptData(encryptedData)
            
            if success {
                return UIImage(data: decryptedData)
            } else {
                // If decryption fails, try loading as unencrypted (for backwards compatibility)
                return UIImage(contentsOfFile: url.path)
            }
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    
    func loadVideoForPlayback(from url: URL, completion: @escaping (URL?) -> Void) {
        do {
            // Read encrypted data
            let encryptedData = try Data(contentsOf: url)
            
            // Decrypt the data
            let (decryptedData, success) = decryptData(encryptedData)
            
            if success {
                // Create a temporary file for playback
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent(UUID().uuidString + ".mov")
                
                try decryptedData.write(to: tempURL)
                completion(tempURL)
            } else {
                // If decryption fails, try using the original file (for backwards compatibility)
                completion(url)
            }
        } catch {
            print("Error preparing video for playback: \(error)")
            completion(nil)
        }
    }
    
    // MARK: - Delete Media
    
    func deleteMedia(at url: URL, completion: @escaping (Bool) -> Void) {
        do {
            try FileManager.default.removeItem(at: url)
            completion(true)
        } catch {
            print("Error deleting file: \(error)")
            completion(false)
        }
    }
    
    // MARK: - Get All Media
    
    func getAllMedia(completion: @escaping ([URL]) -> Void) {
        guard let mediaDirectory = mediaDirectoryURL else {
            completion([])
            return
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: mediaDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            completion(fileURLs)
        } catch {
            print("Error loading media files: \(error)")
            completion([])
        }
    }
    
    // MARK: - Utility Methods
    
    func isVideo(url: URL) -> Bool {
        // For encrypted files, we can't tell by extension anymore
        // Check if we have metadata stored or use another mechanism
        return url.pathExtension.lowercased() == "mov" || url.path.contains("video_")
    }
    
    func isVoiceMemo(url: URL) -> Bool {
        // Check if it's a voice memo based on filename
        return url.path.contains("voiceMemo_")
    }
    
    func generateVideoThumbnail(from url: URL) -> UIImage? {
        // For encrypted videos, we need to decrypt first
        if url.pathExtension.lowercased() == "enc" {
            do {
                // Decrypt to temporary file
                let encryptedData = try Data(contentsOf: url)
                let (decryptedData, success) = decryptData(encryptedData)
                
                if success {
                    // Create a temporary file for thumbnail generation
                    let tempDir = FileManager.default.temporaryDirectory
                    let tempURL = tempDir.appendingPathComponent(UUID().uuidString + ".mov")
                    
                    try decryptedData.write(to: tempURL)
                    
                    // Generate thumbnail
                    let asset = AVAsset(url: tempURL)
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    
                    do {
                        let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil)
                        
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: tempURL)
                        
                        return UIImage(cgImage: cgImage)
                    } catch {
                        print("Error generating thumbnail: \(error)")
                        return nil
                    }
                }
            } catch {
                print("Error decrypting video for thumbnail: \(error)")
                return nil
            }
        }
        
        // Fallback for unencrypted videos
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
}
