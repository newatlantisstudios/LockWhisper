import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    // A switch to toggle biometric authentication.
    private let biometricSwitch: UISwitch = {
       let biometricSwitch = UISwitch()
       biometricSwitch.translatesAutoresizingMaskIntoConstraints = false
       biometricSwitch.isOn = UserDefaults.standard.bool(forKey: "biometricEnabled")
       return biometricSwitch
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Settings"
        setupNavigationBar()
        setupLockWhisperLabel()
        setupBiometricSwitch()  // Add the biometric switch here.
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBar() {
        // Create the tip jar button using the image named "tipJar"
        let tipJarImage = UIImage(named: "tipJar")
        let tipJarButton = UIBarButtonItem(image: tipJarImage, style: .plain, target: self, action: #selector(tipJarTapped))
        navigationItem.rightBarButtonItem = tipJarButton
    }
    
    private func setupLockWhisperLabel() {
        let label = UILabel()
        label.text = "LockWhisper V3"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Constrain the label to the top of the safe area with some padding.
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupBiometricSwitch() {
        let biometricLabel = UILabel()
        biometricLabel.text = "Enable Biometric Authentication"
        biometricLabel.font = UIFont.systemFont(ofSize: 16)
        biometricLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add both the label and the switch to the view.
        view.addSubview(biometricLabel)
        view.addSubview(biometricSwitch)
        
        // Add target to update the stored preference when the switch toggles.
        biometricSwitch.addTarget(self, action: #selector(biometricSwitchToggled(_:)), for: .valueChanged)
        
        // Place the switch and label below the LockWhisper label.
        NSLayoutConstraint.activate([
            biometricLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            biometricLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            biometricSwitch.centerYAnchor.constraint(equalTo: biometricLabel.centerYAnchor),
            biometricSwitch.leadingAnchor.constraint(equalTo: biometricLabel.trailingAnchor, constant: 16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func tipJarTapped() {
        let tipJarVC = TipJarViewController()
        navigationController?.pushViewController(tipJarVC, animated: true)
    }
    
    @objc private func biometricSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "biometricEnabled")
    }
}
