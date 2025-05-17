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
        if BiometricAuthManager.shared.shouldRequireAuthentication() {
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
        
        BiometricAuthManager.shared.authenticateIfNeeded(from: topViewController) { [weak self] success in
            if success {
                self?.removeSecurityView()
            } else {
                // Keep the security view if authentication fails
                // The user will need to manually authenticate when they return to the app
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
}
