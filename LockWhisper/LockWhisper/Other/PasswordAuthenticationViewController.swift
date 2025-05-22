import UIKit

class PasswordAuthenticationViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let passwordTextField = UITextField()
    private let unlockButton = StyledButton()
    private let stackView = UIStackView()
    
    private var authCompletion: ((Bool) -> Void)?
    
    // MARK: - Lifecycle
    
    init(completion: @escaping (Bool) -> Void) {
        self.authCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardHandling()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title
        titleLabel.text = "Enter Password"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        
        // Password field
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.backgroundColor = .secondarySystemBackground
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        // Unlock button
        unlockButton.setTitle("Unlock", for: .normal)
        unlockButton.setStyle(.primary)
        unlockButton.isEnabled = false
        unlockButton.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        
        // Stack view
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(unlockButton)
        
        view.addSubview(stackView)
    }
    
    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            unlockButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func textFieldChanged() {
        unlockButton.isEnabled = !(passwordTextField.text?.isEmpty ?? true)
    }
    
    @objc private func unlockTapped() {
        guard let password = passwordTextField.text else { return }
        
        // Verify password using FakePasswordManager
        if let authMode = FakePasswordManager.shared.verifyPassword(password) {
            // Success - update auth time and dismiss
            BiometricAuthManager.shared.updateAuthenticationTime()
            authCompletion?(true)
            dismiss(animated: true)
        } else {
            // Failed authentication
            showError("Invalid password")
            passwordTextField.text = ""
            unlockButton.isEnabled = false
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}