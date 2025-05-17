import UIKit
import LocalAuthentication

class RecoveryViewController: UIViewController {
    
    // UI Elements
    private let instructionLabel = UILabel()
    private let recoveryKeyTextField = UITextField()
    private let recoveryPINTextField = UITextField()
    private let recoverButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let segmentedControl = UISegmentedControl(items: ["Recovery Key", "Recovery PIN"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Recover Data"
        
        // Close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissViewController)
        )
        
        // Instruction Label
        instructionLabel.text = "Enter your recovery key or PIN to restore your data"
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.font = .systemFont(ofSize: 18, weight: .medium)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Segmented Control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // Recovery Key Text Field
        recoveryKeyTextField.placeholder = "Enter recovery key"
        recoveryKeyTextField.borderStyle = .roundedRect
        recoveryKeyTextField.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        recoveryKeyTextField.autocapitalizationType = .none
        recoveryKeyTextField.autocorrectionType = .no
        recoveryKeyTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recoveryKeyTextField)
        
        // Recovery PIN Text Field
        recoveryPINTextField.placeholder = "Enter 6-digit PIN"
        recoveryPINTextField.borderStyle = .roundedRect
        recoveryPINTextField.font = .systemFont(ofSize: 20, weight: .medium)
        recoveryPINTextField.keyboardType = .numberPad
        recoveryPINTextField.textAlignment = .center
        recoveryPINTextField.isHidden = true
        recoveryPINTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recoveryPINTextField)
        
        // Recover Button
        recoverButton.setTitle("Recover Data", for: .normal)
        recoverButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        recoverButton.backgroundColor = .systemBlue
        recoverButton.setTitleColor(.white, for: .normal)
        recoverButton.layer.cornerRadius = 10
        recoverButton.translatesAutoresizingMaskIntoConstraints = false
        recoverButton.addTarget(self, action: #selector(recoverData), for: .touchUpInside)
        view.addSubview(recoverButton)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Warning Label
        let warningLabel = UILabel()
        warningLabel.text = "⚠️ Recovery will restore data from your last backup. Any current data will be overwritten."
        warningLabel.textColor = .systemOrange
        warningLabel.font = .systemFont(ofSize: 14)
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(warningLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            segmentedControl.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 30),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            recoveryKeyTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 30),
            recoveryKeyTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recoveryKeyTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recoveryKeyTextField.heightAnchor.constraint(equalToConstant: 50),
            
            recoveryPINTextField.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 30),
            recoveryPINTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recoveryPINTextField.widthAnchor.constraint(equalToConstant: 150),
            recoveryPINTextField.heightAnchor.constraint(equalToConstant: 50),
            
            recoverButton.topAnchor.constraint(equalTo: recoveryKeyTextField.bottomAnchor, constant: 40),
            recoverButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recoverButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recoverButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: recoverButton.bottomAnchor, constant: 30),
            
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            warningLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
    }
    
    @objc private func segmentChanged() {
        let isRecoveryKey = segmentedControl.selectedSegmentIndex == 0
        recoveryKeyTextField.isHidden = !isRecoveryKey
        recoveryPINTextField.isHidden = isRecoveryKey
        
        if isRecoveryKey {
            recoveryKeyTextField.becomeFirstResponder()
        } else {
            recoveryPINTextField.becomeFirstResponder()
        }
    }
    
    @objc private func recoverData() {
        let isRecoveryKey = segmentedControl.selectedSegmentIndex == 0
        
        if isRecoveryKey {
            guard let recoveryKey = recoveryKeyTextField.text, !recoveryKey.isEmpty else {
                showError("Please enter your recovery key")
                return
            }
            recoverWithKey(recoveryKey)
        } else {
            guard let pin = recoveryPINTextField.text, pin.count == 6 else {
                showError("Please enter a valid 6-digit PIN")
                return
            }
            
            guard RecoveryManager.shared.verifyRecoveryPIN(pin) else {
                showError("Invalid recovery PIN")
                return
            }
            
            // If PIN is valid, we need to get the actual recovery key
            // In a real implementation, this would involve a secure key derivation process
            showError("PIN recovery requires stored recovery key. Please use recovery key option.")
        }
    }
    
    private func recoverWithKey(_ key: String) {
        activityIndicator.startAnimating()
        recoverButton.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try RecoveryManager.shared.recoverData(with: key)
                
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.showSuccess()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.recoverButton.isEnabled = true
                    self?.showError("Recovery failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showSuccess() {
        let alert = UIAlertController(
            title: "Recovery Successful",
            message: "Your data has been successfully restored.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true) {
                // Restart the app or navigate to main screen
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    // Recreate the root view controller to reload all data
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let rootController = storyboard.instantiateInitialViewController() {
                        window.rootViewController = rootController
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
}