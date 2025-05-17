import Foundation
import UIKit
import LocalAuthentication

/// Manager responsible for auto-destruct functionality
class AutoDestructManager {
    static let shared = AutoDestructManager()
    
    private init() {}
    
    // MARK: - Integration with BiometricAuthManager
    
    /// Handle authentication result
    func handleAuthenticationResult(success: Bool) {
        if success {
            resetFailedAttempts()
        } else {
            incrementFailedAttempts()
        }
    }
    
    // MARK: - Auto-Destruct Configuration
    
    /// Check if auto-destruct is enabled
    var isAutoDestructEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.autoDestructEnabled)
    }
    
    /// Get maximum failed attempts allowed
    var maxFailedAttempts: Int {
        let savedValue = UserDefaults.standard.integer(forKey: Constants.maxFailedAttempts)
        return savedValue > 0 ? savedValue : Constants.defaultMaxFailedAttempts
    }
    
    /// Get current failed attempts count
    var failedAttempts: Int {
        return UserDefaults.standard.integer(forKey: Constants.failedUnlockAttempts)
    }
    
    /// Check if auto-destruct is locked (max attempts reached)
    var isAutoDestructLocked: Bool {
        return UserDefaults.standard.bool(forKey: Constants.autoDestructLocked)
    }
    
    // MARK: - Failed Attempts Management
    
    /// Increment failed attempts counter
    func incrementFailedAttempts() {
        guard isAutoDestructEnabled else { return }
        
        let currentAttempts = failedAttempts + 1
        UserDefaults.standard.set(currentAttempts, forKey: Constants.failedUnlockAttempts)
        
        if currentAttempts >= maxFailedAttempts {
            triggerAutoDestruct()
        }
    }
    
    /// Reset failed attempts counter
    func resetFailedAttempts() {
        UserDefaults.standard.set(0, forKey: Constants.failedUnlockAttempts)
        UserDefaults.standard.set(false, forKey: Constants.autoDestructLocked)
    }
    
    // MARK: - Auto-Destruct Trigger
    
    /// Trigger auto-destruct mechanism
    func triggerAutoDestruct() {
        // Set auto-destruct lock
        UserDefaults.standard.set(true, forKey: Constants.autoDestructLocked)
        
        // Log the event (for debugging/forensics)
        print("[SECURITY] Auto-destruct triggered after \(failedAttempts) failed attempts")
        
        // Check if recovery is enabled
        if RecoveryManager.shared.isRecoveryEnabled {
            do {
                // Create backup before destruction
                _ = try RecoveryManager.shared.createPreDestructionBackup()
                print("[SECURITY] Recovery backup created successfully")
            } catch {
                print("[SECURITY] Failed to create recovery backup: \(error)")
            }
        }
        
        // Perform secure data wipe
        do {
            try SecureDataWipeManager.shared.performCompleteDataWipe()
            
            // Show alert before terminating
            DispatchQueue.main.async {
                self.showAutoDestructAlert()
            }
        } catch {
            print("[SECURITY] Error during auto-destruct: \(error)")
            // Still terminate the app even if wipe fails
            DispatchQueue.main.async {
                self.terminateApp()
            }
        }
    }
    
    /// Manual trigger for auto-destruct (for testing or emergency)
    func manualTrigger(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Require biometric authentication for manual trigger
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                                   localizedReason: "Authenticate to trigger emergency data wipe") { success, error in
                DispatchQueue.main.async {
                    if success {
                        do {
                            // Check if recovery is enabled
                            if RecoveryManager.shared.isRecoveryEnabled {
                                _ = try? RecoveryManager.shared.createPreDestructionBackup()
                            }
                            
                            try SecureDataWipeManager.shared.performCompleteDataWipe()
                            completion(true)
                            self.showAutoDestructAlert()
                        } catch {
                            completion(false)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            // Fallback to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, 
                                   localizedReason: "Authenticate to trigger emergency data wipe") { success, error in
                DispatchQueue.main.async {
                    if success {
                        do {
                            // Check if recovery is enabled
                            if RecoveryManager.shared.isRecoveryEnabled {
                                _ = try? RecoveryManager.shared.createPreDestructionBackup()
                            }
                            
                            try SecureDataWipeManager.shared.performCompleteDataWipe()
                            completion(true)
                            self.showAutoDestructAlert()
                        } catch {
                            completion(false)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    // MARK: - UI Handling
    
    private func showAutoDestructAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            terminateApp()
            return
        }
        
        let alert = UIAlertController(
            title: "Security Alert",
            message: "All app data has been wiped for security reasons.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.terminateApp()
        })
        
        window.rootViewController?.present(alert, animated: false) {
            // Auto-dismiss and terminate after 5 seconds if user doesn't tap OK
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.terminateApp()
            }
        }
    }
    
    private func terminateApp() {
        // Clear remaining memory
        autoreleasepool {
            // Force memory cleanup
            NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        }
        
        // Terminate the app
        exit(0)
    }
    
    // MARK: - Remote Trigger Support
    
    /// Check for remote trigger (can be implemented with push notifications or server polling)
    func checkForRemoteTrigger() {
        // This method could be implemented to check for remote wipe commands
        // For example, through push notifications or periodic server checks
        // For now, this is a placeholder for future implementation
    }
    
    // MARK: - Panic Mode
    
    /// Enable panic mode - triggers auto-destruct with specific gesture/action
    func enablePanicMode(withGesture gesture: UIGestureRecognizer) {
        // This could be implemented to trigger auto-destruct with a specific gesture
        // For example, a 5-finger long press or specific swipe pattern
    }
}