import Foundation
import LocalAuthentication
import UIKit

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
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
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                              localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    self.updateAuthenticationTime()
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
                let alert = UIAlertController(
                    title: "Authentication Failed",
                    message: "Biometric authentication was not successful. Please try again.",
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
}