import UIKit

class RemoteWipeConfigViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Remote Wipe Configuration"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let remoteWipeSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.isOn = UserDefaults.standard.bool(forKey: "remoteWipeEnabled")
        return switchControl
    }()
    
    private let pinCodeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter remote wipe PIN code"
        textField.isSecureTextEntry = true
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = """
        When enabled, you can trigger a remote data wipe by:
        • Opening the app and entering your PIN code 3 times
        • Sending a special notification (requires setup)
        • Using a companion app or web interface
        """
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Configuration", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        enableKeyboardHandling()
        setupUI()
        setupActions()
        loadConfiguration()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(remoteWipeSwitch)
        view.addSubview(pinCodeTextField)
        view.addSubview(infoLabel)
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            remoteWipeSwitch.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            remoteWipeSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            pinCodeTextField.topAnchor.constraint(equalTo: remoteWipeSwitch.bottomAnchor, constant: 20),
            pinCodeTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pinCodeTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pinCodeTextField.heightAnchor.constraint(equalToConstant: 44),
            
            infoLabel.topAnchor.constraint(equalTo: pinCodeTextField.bottomAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add label for remote wipe switch
        let switchLabel = UILabel()
        switchLabel.text = "Enable Remote Wipe"
        switchLabel.font = UIFont.systemFont(ofSize: 16)
        switchLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(switchLabel)
        
        NSLayoutConstraint.activate([
            switchLabel.centerYAnchor.constraint(equalTo: remoteWipeSwitch.centerYAnchor),
            switchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveConfiguration), for: .touchUpInside)
        remoteWipeSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        remoteWipeSwitch.isOn = UserDefaults.standard.bool(forKey: "remoteWipeEnabled")
        
        if let savedPIN = UserDefaults.standard.string(forKey: "remoteWipePIN") {
            // Don't show the actual PIN for security
            pinCodeTextField.text = String(repeating: "•", count: savedPIN.count)
        }
        
        updateUIState()
    }
    
    @objc private func switchToggled() {
        updateUIState()
    }
    
    private func updateUIState() {
        let isEnabled = remoteWipeSwitch.isOn
        pinCodeTextField.isEnabled = isEnabled
        pinCodeTextField.alpha = isEnabled ? 1.0 : 0.5
    }
    
    @objc private func saveConfiguration() {
        guard let pinCode = pinCodeTextField.text, !pinCode.isEmpty else {
            showAlert(title: "Error", message: "Please enter a PIN code")
            return
        }
        
        // Validate PIN code (minimum 4 digits)
        if pinCode.count < 4 || !pinCode.allSatisfy({ $0.isNumber }) {
            showAlert(title: "Invalid PIN", message: "PIN must be at least 4 digits")
            return
        }
        
        // Save configuration
        UserDefaults.standard.set(remoteWipeSwitch.isOn, forKey: "remoteWipeEnabled")
        
        // Only save new PIN if it's not the masked version
        if !pinCode.contains("•") {
            UserDefaults.standard.set(pinCode, forKey: "remoteWipePIN")
        }
        
        showAlert(title: "Success", message: "Remote wipe configuration saved") { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}