import UIKit
import LocalAuthentication

class RecoverySettingsViewController: UIViewController {
    
    // UI Elements
    private let recoveryToggle = UISwitch()
    private let timeWindowLabel = UILabel()
    private let timeWindowSlider = UISlider()
    private let generateKeyButton = UIButton(type: .system)
    private let generatePINButton = UIButton(type: .system)
    private let recoveryKeyLabel = UILabel()
    private let recoveryPINLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Recovery Settings"
        
        // Recovery Enable Toggle
        let toggleLabel = UILabel()
        toggleLabel.text = "Enable Recovery"
        toggleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleLabel)
        
        recoveryToggle.translatesAutoresizingMaskIntoConstraints = false
        recoveryToggle.addTarget(self, action: #selector(recoveryToggleChanged), for: .valueChanged)
        view.addSubview(recoveryToggle)
        
        // Time Window Settings
        let timeWindowTitleLabel = UILabel()
        timeWindowTitleLabel.text = "Recovery Time Window"
        timeWindowTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        timeWindowTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeWindowTitleLabel)
        
        timeWindowLabel.text = "24 hours"
        timeWindowLabel.textAlignment = .right
        timeWindowLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeWindowLabel)
        
        timeWindowSlider.minimumValue = 1
        timeWindowSlider.maximumValue = 168 // 7 days in hours
        timeWindowSlider.value = 24
        timeWindowSlider.translatesAutoresizingMaskIntoConstraints = false
        timeWindowSlider.addTarget(self, action: #selector(timeWindowChanged), for: .valueChanged)
        view.addSubview(timeWindowSlider)
        
        // Generate Recovery Key Button
        generateKeyButton.setTitle("Generate Recovery Key", for: .normal)
        generateKeyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        generateKeyButton.translatesAutoresizingMaskIntoConstraints = false
        generateKeyButton.addTarget(self, action: #selector(generateRecoveryKey), for: .touchUpInside)
        view.addSubview(generateKeyButton)
        
        // Recovery Key Display
        recoveryKeyLabel.numberOfLines = 0
        recoveryKeyLabel.textAlignment = .center
        recoveryKeyLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        recoveryKeyLabel.textColor = .systemBlue
        recoveryKeyLabel.isUserInteractionEnabled = true
        recoveryKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        let keyTap = UITapGestureRecognizer(target: self, action: #selector(copyRecoveryKey))
        recoveryKeyLabel.addGestureRecognizer(keyTap)
        view.addSubview(recoveryKeyLabel)
        
        // Generate Recovery PIN Button
        generatePINButton.setTitle("Generate Recovery PIN", for: .normal)
        generatePINButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        generatePINButton.translatesAutoresizingMaskIntoConstraints = false
        generatePINButton.addTarget(self, action: #selector(generateRecoveryPIN), for: .touchUpInside)
        view.addSubview(generatePINButton)
        
        // Recovery PIN Display
        recoveryPINLabel.font = .systemFont(ofSize: 24, weight: .bold)
        recoveryPINLabel.textAlignment = .center
        recoveryPINLabel.textColor = .systemGreen
        recoveryPINLabel.isUserInteractionEnabled = true
        recoveryPINLabel.translatesAutoresizingMaskIntoConstraints = false
        let pinTap = UITapGestureRecognizer(target: self, action: #selector(copyRecoveryPIN))
        recoveryPINLabel.addGestureRecognizer(pinTap)
        view.addSubview(recoveryPINLabel)
        
        // Info Label
        let infoLabel = UILabel()
        infoLabel.text = "Tap the recovery key or PIN to copy to clipboard"
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Toggle
            toggleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            toggleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            
            recoveryToggle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            recoveryToggle.centerYAnchor.constraint(equalTo: toggleLabel.centerYAnchor),
            
            // Time Window
            timeWindowTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            timeWindowTitleLabel.topAnchor.constraint(equalTo: toggleLabel.bottomAnchor, constant: 40),
            
            timeWindowLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            timeWindowLabel.centerYAnchor.constraint(equalTo: timeWindowTitleLabel.centerYAnchor),
            
            timeWindowSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            timeWindowSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            timeWindowSlider.topAnchor.constraint(equalTo: timeWindowTitleLabel.bottomAnchor, constant: 10),
            
            // Recovery Key
            generateKeyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generateKeyButton.topAnchor.constraint(equalTo: timeWindowSlider.bottomAnchor, constant: 40),
            
            recoveryKeyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            recoveryKeyLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            recoveryKeyLabel.topAnchor.constraint(equalTo: generateKeyButton.bottomAnchor, constant: 20),
            
            // Recovery PIN
            generatePINButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generatePINButton.topAnchor.constraint(equalTo: recoveryKeyLabel.bottomAnchor, constant: 40),
            
            recoveryPINLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recoveryPINLabel.topAnchor.constraint(equalTo: generatePINButton.bottomAnchor, constant: 20),
            
            // Info
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadCurrentSettings() {
        recoveryToggle.isOn = RecoveryManager.shared.isRecoveryEnabled
        
        let hours = RecoveryManager.shared.recoveryTimeWindow / 3600
        timeWindowSlider.value = Float(hours)
        updateTimeWindowLabel()
        
        updateButtonStates()
    }
    
    private func updateButtonStates() {
        let isEnabled = recoveryToggle.isOn
        generateKeyButton.isEnabled = isEnabled
        generatePINButton.isEnabled = isEnabled
        timeWindowSlider.isEnabled = isEnabled
        
        if !isEnabled {
            recoveryKeyLabel.text = ""
            recoveryPINLabel.text = ""
        }
    }
    
    private func updateTimeWindowLabel() {
        let hours = Int(timeWindowSlider.value)
        if hours == 1 {
            timeWindowLabel.text = "1 hour"
        } else if hours < 24 {
            timeWindowLabel.text = "\(hours) hours"
        } else {
            let days = hours / 24
            if days == 1 {
                timeWindowLabel.text = "1 day"
            } else {
                timeWindowLabel.text = "\(days) days"
            }
        }
    }
    
    @objc private func recoveryToggleChanged() {
        RecoveryManager.shared.isRecoveryEnabled = recoveryToggle.isOn
        updateButtonStates()
        
        if !recoveryToggle.isOn {
            // Clear any existing recovery data
            try? KeychainHelper.shared.delete(key: "com.lockwhisper.recovery.key")
            UserDefaults.standard.removeObject(forKey: Constants.recoveryPINHash)
        }
    }
    
    @objc private func timeWindowChanged() {
        updateTimeWindowLabel()
        let seconds = TimeInterval(timeWindowSlider.value * 3600)
        RecoveryManager.shared.recoveryTimeWindow = seconds
    }
    
    @objc private func generateRecoveryKey() {
        authenticateUser { [weak self] success in
            if success {
                do {
                    let recoveryKey = try RecoveryManager.shared.generateRecoveryKey()
                    self?.recoveryKeyLabel.text = recoveryKey
                    
                    // Show success alert
                    let alert = UIAlertController(
                        title: "Recovery Key Generated",
                        message: "Your recovery key has been generated. Please save it in a secure location.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                        UIPasteboard.general.string = recoveryKey
                        self?.showCopiedToast("Recovery key copied")
                    })
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self?.present(alert, animated: true)
                } catch {
                    self?.showError("Failed to generate recovery key: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func generateRecoveryPIN() {
        authenticateUser { [weak self] success in
            if success {
                let pin = RecoveryManager.shared.generateRecoveryPIN()
                self?.recoveryPINLabel.text = pin
                
                // Show success alert
                let alert = UIAlertController(
                    title: "Recovery PIN Generated",
                    message: "Your 6-digit recovery PIN has been generated. Please memorize it or save it securely.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                    UIPasteboard.general.string = pin
                    self?.showCopiedToast("Recovery PIN copied")
                })
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self?.present(alert, animated: true)
            }
        }
    }
    
    @objc private func copyRecoveryKey() {
        guard let key = recoveryKeyLabel.text, !key.isEmpty else { return }
        UIPasteboard.general.string = key
        showCopiedToast("Recovery key copied")
    }
    
    @objc private func copyRecoveryPIN() {
        guard let pin = recoveryPINLabel.text, !pin.isEmpty else { return }
        UIPasteboard.general.string = pin
        showCopiedToast("Recovery PIN copied")
    }
    
    private func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Authenticate to manage recovery settings") { success, error in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            // Fallback to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: "Authenticate to manage recovery settings") { success, error in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showCopiedToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            toast.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
            toast.alpha = 0
        }) { _ in
            toast.removeFromSuperview()
        }
    }
}