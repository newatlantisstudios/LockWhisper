import Foundation
import LocalAuthentication
import UIKit

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private var failedAttempts: Int {
        get { UserDefaults.standard.integer(forKey: Constants.failedUnlockAttempts) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.failedUnlockAttempts) }
    }
    
    private var maxFailedAttempts: Int {
        let savedValue = UserDefaults.standard.integer(forKey: Constants.maxFailedAttempts)
        return savedValue > 0 ? savedValue : Constants.defaultMaxFailedAttempts
    }
    
    private var isLocked: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.autoDestructLocked) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.autoDestructLocked) }
    }
    
    private init() {}
    
    /// Checks if authentication is required based on settings and intervals
    func shouldRequireAuthentication() -> Bool {
        // Check if biometric authentication is enabled
        guard UserDefaults.standard.bool(forKey: Constants.biometricEnabled) else {
            return false
        }
        
        let interval = UserDefaults.standard.integer(forKey: Constants.biometricCheckInterval)
        
        // If interval is 0 (Never), only require auth on first launch (no last auth time stored)
        if interval == 0 {
            return UserDefaults.standard.double(forKey: Constants.lastBiometricAuthTime) == 0
        }
        
        // Get the last authentication time
        let lastAuthTime = UserDefaults.standard.double(forKey: Constants.lastBiometricAuthTime)
        
        // If never authenticated, require authentication
        if lastAuthTime == 0 {
            return true
        }
        
        // Calculate if interval has passed
        let currentTime = Date().timeIntervalSince1970
        let intervalInSeconds = Double(interval * 60) // Convert minutes to seconds
        
        return (currentTime - lastAuthTime) >= intervalInSeconds
    }
    
    /// Updates the last authentication time
    func updateAuthenticationTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Constants.lastBiometricAuthTime)
    }
    
    /// Performs biometric authentication
    func authenticate(reason: String = "Authenticate to access the app", 
                     completion: @escaping (Bool, Error?) -> Void) {
        let autoDestructEnabled = UserDefaults.standard.bool(forKey: Constants.autoDestructEnabled)
        
        // Check if app is locked due to too many failed attempts (only if auto-destruct is enabled)
        if autoDestructEnabled && (isLocked || failedAttempts >= maxFailedAttempts) {
            triggerAutoDestruct()
            completion(false, NSError(domain: "com.lockwhisper", code: -1, 
                                    userInfo: [NSLocalizedDescriptionKey: "App is locked due to too many failed attempts"]))
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            handleFailedAttempt()
            completion(false, error)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                              localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.updateAuthenticationTime()
                    self.resetFailedAttempts()
                } else {
                    self.handleFailedAttempt()
                }
                completion(success, authError)
            }
        }
    }
    
    /// Presents authentication if required, with a view controller to present alerts
    func authenticateIfNeeded(from viewController: UIViewController, completion: ((Bool) -> Void)? = nil) {
        guard shouldRequireAuthentication() else {
            completion?(true)
            return
        }
        
        authenticate { [weak viewController] success, error in
            if !success {
                let autoDestructEnabled = UserDefaults.standard.bool(forKey: Constants.autoDestructEnabled)
                let remainingAttempts = self.maxFailedAttempts - self.failedAttempts
                
                var message = "Biometric authentication was not successful."
                if autoDestructEnabled && remainingAttempts > 0 {
                    message += " You have \(remainingAttempts) attempts remaining."
                } else if autoDestructEnabled && remainingAttempts <= 0 {
                    message = "Maximum attempts exceeded. App will be wiped for security."
                }
                
                let alert = UIAlertController(
                    title: "Authentication Failed",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    completion?(false)
                })
                viewController?.present(alert, animated: true)
            } else {
                completion?(true)
            }
        }
    }
    
    // MARK: - Failed Attempts Management
    
    private func handleFailedAttempt() {
        let autoDestructEnabled = UserDefaults.standard.bool(forKey: Constants.autoDestructEnabled)
        
        if autoDestructEnabled {
            failedAttempts += 1
            if failedAttempts >= maxFailedAttempts {
                isLocked = true
                triggerAutoDestruct()
            }
        }
    }
    
    private func resetFailedAttempts() {
        failedAttempts = 0
        isLocked = false
    }
    
    // MARK: - Auto-Destruct Mechanism
    
    private func triggerAutoDestruct() {
        // This is a critical security feature that wipes all app data
        print("🚨 AUTO-DESTRUCT TRIGGERED: Wiping all app data due to excessive failed attempts")
        
        // Reset all UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear all keychain items
        clearKeychain()
        
        // Delete CoreData stores
        deleteCoreDataStores()
        
        // Delete all encrypted files
        deleteEncryptedFiles()
        
        // Reset app to initial state
        UserDefaults.standard.synchronize()
        
        // Force app to quit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
    
    private func clearKeychain() {
        // Clear all keychain items for each service
        let services = [
            Constants.contactsService,
            Constants.notepadService,
            Constants.passwordsService,
            Constants.pgpService,
            Constants.todoService,
            Constants.fileVaultService
        ]
        
        for service in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    private func deleteCoreDataStores() {
        // Get the persistent container's store URLs
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = urls.first else { return }
        
        let storeURL = documentsDirectory.appendingPathComponent("NotepadModel.sqlite")
        let storeURLShm = documentsDirectory.appendingPathComponent("NotepadModel.sqlite-shm")
        let storeURLWal = documentsDirectory.appendingPathComponent("NotepadModel.sqlite-wal")
        
        // Delete all CoreData files
        try? FileManager.default.removeItem(at: storeURL)
        try? FileManager.default.removeItem(at: storeURLShm)
        try? FileManager.default.removeItem(at: storeURLWal)
    }
    
    private func deleteEncryptedFiles() {
        // Delete all files in the encrypted files directory
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsDirectory = urls.first else { return }
        
        let encryptedFilesDirectory = documentsDirectory.appendingPathComponent("EncryptedFiles")
        if FileManager.default.fileExists(atPath: encryptedFilesDirectory.path) {
            try? FileManager.default.removeItem(at: encryptedFilesDirectory)
        }
    }
}