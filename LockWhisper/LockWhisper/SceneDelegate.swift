import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var securityView: UIView?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        let rootViewController = DashboardViewController()
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Remove security overlay when app becomes active
        removeSecurityView()
        
        // Check if authentication is required
        if shouldRequireAuthentication() {
            authenticateUser()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Add security overlay when app is about to move to background
        showSecurityView()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from background to foreground.
        // Remove security view first (will be re-added if auth fails)
        removeSecurityView()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from foreground to background.
        // Ensure security view is shown
        showSecurityView()
    }
    
    // MARK: - Authentication Methods
    
    private func shouldRequireAuthentication() -> Bool {
        // Check if we have a real password set
        let hasRealPassword = FakePasswordManager.shared.getStoredPassword(for: Constants.realPasswordService, account: Constants.realPasswordAccount) != nil
        
        // If no real password is set, use biometric only
        if !hasRealPassword {
            return BiometricAuthManager.shared.shouldRequireAuthentication()
        }
        
        // If we have a password system, always require authentication on app launch
        return true
    }
    
    // MARK: - Security View Methods
    
    private func showSecurityView() {
        guard securityView == nil else { return }
        
        // Create a full-screen overlay to hide sensitive content
        let view = UIView(frame: window?.bounds ?? .zero)
        view.backgroundColor = .systemBackground
        
        // Add app logo or blur effect
        let logoImageView = UIImageView(image: UIImage(named: "AppIcon"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        // Check failed attempts and show warning if necessary (only if auto-destruct is enabled)
        let autoDestructEnabled = UserDefaults.standard.bool(forKey: Constants.autoDestructEnabled)
        let failedAttempts = UserDefaults.standard.integer(forKey: Constants.failedUnlockAttempts)
        let maxFailedAttempts = UserDefaults.standard.integer(forKey: Constants.maxFailedAttempts)
        let maxAttempts = maxFailedAttempts > 0 ? maxFailedAttempts : Constants.defaultMaxFailedAttempts
        let isAutoDestructLocked = UserDefaults.standard.bool(forKey: Constants.autoDestructLocked)
        
        if autoDestructEnabled && failedAttempts > 0 && failedAttempts < maxAttempts && !isAutoDestructLocked {
            let warningLabel = UILabel()
            warningLabel.text = "⚠️ Warning: \(maxAttempts - failedAttempts) attempts remaining"
            warningLabel.textColor = .systemRed
            warningLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            warningLabel.textAlignment = .center
            warningLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(warningLabel)
            
            NSLayoutConstraint.activate([
                warningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                warningLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
                warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
        
        // Show recovery option if auto-destruct is locked
        if isAutoDestructLocked && RecoveryManager.shared.isRecoveryEnabled {
            let lockedLabel = UILabel()
            lockedLabel.text = "🔒 Device Locked - Maximum attempts exceeded"
            lockedLabel.textColor = .systemRed
            lockedLabel.font = .systemFont(ofSize: 18, weight: .bold)
            lockedLabel.textAlignment = .center
            lockedLabel.numberOfLines = 0
            lockedLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(lockedLabel)
            
            let recoveryButton = UIButton(type: .system)
            recoveryButton.setTitle("Recover Data", for: .normal)
            recoveryButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            recoveryButton.backgroundColor = .systemBlue
            recoveryButton.setTitleColor(.white, for: .normal)
            recoveryButton.layer.cornerRadius = 10
            recoveryButton.translatesAutoresizingMaskIntoConstraints = false
            recoveryButton.addTarget(self, action: #selector(showRecoveryScreen), for: .touchUpInside)
            view.addSubview(recoveryButton)
            
            NSLayoutConstraint.activate([
                lockedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                lockedLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
                lockedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                lockedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                recoveryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                recoveryButton.topAnchor.constraint(equalTo: lockedLabel.bottomAnchor, constant: 30),
                recoveryButton.widthAnchor.constraint(equalToConstant: 200),
                recoveryButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        window?.addSubview(view)
        securityView = view
    }
    
    private func removeSecurityView() {
        securityView?.removeFromSuperview()
        securityView = nil
    }
    
    private func authenticateUser() {
        guard let topViewController = getTopViewController() else { return }
        
        // Show security view while authenticating
        showSecurityView()
        
        // Check if password is set
        let hasRealPassword = FakePasswordManager.shared.getStoredPassword(for: Constants.realPasswordService, account: Constants.realPasswordAccount) != nil
        
        if hasRealPassword {
            // Use password authentication
            let passwordAuthVC = PasswordAuthenticationViewController { [weak self] success in
                if success {
                    self?.removeSecurityView()
                } else {
                    // Keep the security view if authentication fails
                }
            }
            passwordAuthVC.modalPresentationStyle = .fullScreen
            topViewController.present(passwordAuthVC, animated: false)
        } else {
            // Fall back to biometric authentication only
            BiometricAuthManager.shared.authenticateIfNeeded(from: topViewController) { [weak self] success in
                if success {
                    self?.removeSecurityView()
                } else {
                    // Keep the security view if authentication fails
                }
            }
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let rootViewController = window?.rootViewController else { return nil }
        
        if let navigationController = rootViewController as? UINavigationController {
            return navigationController.topViewController ?? navigationController
        }
        
        return rootViewController
    }
    
    @objc private func showRecoveryScreen() {
        let recoveryVC = RecoveryViewController()
        let navigationController = UINavigationController(rootViewController: recoveryVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        if let topViewController = getTopViewController() {
            topViewController.present(navigationController, animated: true)
        }
    }
}
