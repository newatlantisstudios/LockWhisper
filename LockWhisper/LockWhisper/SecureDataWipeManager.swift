import Foundation
import UIKit
import CoreData
import Security

/// Manager responsible for securely wiping all application data
class SecureDataWipeManager {
    static let shared = SecureDataWipeManager()
    
    private init() {}
    
    /// Performs a complete secure data wipe of all application data
    func performCompleteDataWipe() throws {
        try wipeKeychain()
        try wipeUserDefaults()
        try wipeCoreData()
        try wipeFileSystem()
        try wipeTemporaryFiles()
        clearMemoryCache()
    }
    
    /// Wipe all keychain items
    private func wipeKeychain() throws {
        let keychainIdentifiers = [
            Constants.privatePGPKey,
            Constants.contactsEncryptionKey,
            Constants.notepadEncryptionKey,
            Constants.passwordsEncryptionKey,
            Constants.pgpEncryptionKey,
            Constants.todoEncryptionKey,
            Constants.fileVaultEncryptionKey
        ]
        
        for identifier in keychainIdentifiers {
            try? KeychainHelper.shared.delete(key: identifier)
        }
        
        // Wipe all keychain items for the app
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for itemClass in secItemClasses {
            let query: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    /// Wipe all UserDefaults
    private func wipeUserDefaults() throws {
        // Get app domain
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        
        // Clear standard UserDefaults
        UserDefaults.standard.dictionaryRepresentation().keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /// Wipe CoreData
    private func wipeCoreData() throws {
        let coreDataManager = CoreDataManager.shared
        let context = coreDataManager.context
        
        // Delete all entities
        let entityNames = [Constants.noteEntity, Constants.todoItemEntity]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Error deleting \(entityName): \(error)")
            }
        }
        
        // Save the context
        try context.save()
        
        // Delete persistent stores
        let coordinator = coreDataManager.persistentContainer.persistentStoreCoordinator
        let stores = coordinator.persistentStores
        
        for store in stores {
            if let storeURL = store.url {
                try coordinator.destroyPersistentStore(at: storeURL, ofType: store.type, options: nil)
                try FileManager.default.removeItem(at: storeURL)
                
                // Remove associated files (wal, shm)
                let walURL = storeURL.appendingPathExtension("wal")
                let shmURL = storeURL.appendingPathExtension("shm")
                try? FileManager.default.removeItem(at: walURL)
                try? FileManager.default.removeItem(at: shmURL)
            }
        }
    }
    
    /// Wipe file system
    private func wipeFileSystem() throws {
        // Delete documents directory
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
        
        // Delete library directory
        if let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let excludedDirs = ["Caches", "Preferences", "Application Support"]
            let fileURLs = try FileManager.default.contentsOfDirectory(at: libraryURL, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                let lastPathComponent = fileURL.lastPathComponent
                if !excludedDirs.contains(lastPathComponent) {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        }
        
        // Delete caches
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    /// Wipe temporary files
    private func wipeTemporaryFiles() throws {
        let tmpDirectory = FileManager.default.temporaryDirectory
        let fileURLs = try FileManager.default.contentsOfDirectory(at: tmpDirectory, includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// Clear memory cache
    private func clearMemoryCache() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // Force memory warning to trigger cleanup
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// Perform secure overwrite of a file
    private func securelyOverwriteFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        let fileHandle = try FileHandle(forWritingTo: url)
        defer { fileHandle.closeFile() }
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        
        // Overwrite with random data multiple times
        for _ in 0..<3 {
            fileHandle.seek(toFileOffset: 0)
            
            let chunkSize: Int = 1024 * 1024 // 1MB chunks
            var remainingBytes = Int(fileSize)
            
            while remainingBytes > 0 {
                let bytesToWrite = min(chunkSize, remainingBytes)
                let randomData = Data((0..<bytesToWrite).map { _ in UInt8.random(in: 0...255) })
                fileHandle.write(randomData)
                remainingBytes -= bytesToWrite
            }
            
            fileHandle.synchronizeFile()
        }
        
        // Finally overwrite with zeros
        fileHandle.seek(toFileOffset: 0)
        let zeroData = Data(repeating: 0, count: Int(fileSize))
        fileHandle.write(zeroData)
        fileHandle.synchronizeFile()
    }
}