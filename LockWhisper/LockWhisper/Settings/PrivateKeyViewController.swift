import UIKit
import LocalAuthentication

class PrivateKeyViewController: UIViewController {
    private let privateTextView = UITextView()
    private let keychainKey = "privatePGPKey"
    private let stackView = UIStackView()
    private let saveButton = StyledButton()
    private let eraseButton = StyledButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Private Key"
        view.backgroundColor = .systemBackground
        setupUI()
        loadPrivateKey()
    }
    
    private func setupUI() {
        // Label
        let label = UILabel()
        label.text = "My Private PGP Key"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // TextView
        privateTextView.font = UIFont.systemFont(ofSize: 16)
        privateTextView.isEditable = true
        privateTextView.isScrollEnabled = true
        privateTextView.layer.borderColor = UIColor.systemGray.cgColor
        privateTextView.layer.borderWidth = 1
        privateTextView.layer.cornerRadius = 8
        privateTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(privateTextView)
        
        // Stack View
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Erase Button
        eraseButton.setTitle("Erase and Save", for: .normal)
        eraseButton.setStyle(.warning)
        eraseButton.addTarget(self, action: #selector(confirmErase), for: .touchUpInside)
        
        // Save Button
        saveButton.setTitle("Save to iOS keychain", for: .normal)
        saveButton.setStyle(.primary)
        saveButton.addTarget(self, action: #selector(confirmSave), for: .touchUpInside)
        
        // Add buttons to stack view
        stackView.addArrangedSubview(eraseButton)
        stackView.addArrangedSubview(saveButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            privateTextView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            privateTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            privateTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            privateTextView.heightAnchor.constraint(equalToConstant: 150),
            
            stackView.topAnchor.constraint(equalTo: privateTextView.bottomAnchor, constant: 30),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func loadPrivateKey() {
        do {
            if let savedKey = try KeychainHelper.shared.get(key: keychainKey) {
                privateTextView.text = savedKey
            } else {
                privateTextView.text = "Enter your private PGP key here"
            }
        } catch {
            showAlert(title: "Error", message: "Failed to load the private key from the Keychain.")
        }
    }
    
    @objc private func confirmSave() {
        let alert = UIAlertController(
            title: "Confirm Save",
            message: "Are you sure you want to save this private key to the iOS keychain?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.savePrivateKey()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func confirmErase() {
        let alert = UIAlertController(
            title: "Warning",
            message: "This will erase the current key and save an empty value. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Erase", style: .destructive) { [weak self] _ in
            self?.eraseAndSave()
        })
        
        present(alert, animated: true)
    }
    
    private func savePrivateKey() {
        guard let text = privateTextView.text, !text.isEmpty else {
            showAlert(title: "Error", message: "Private key cannot be empty.")
            return
        }
        
        do {
            try KeychainHelper.shared.save(key: keychainKey, value: text)
            showAlert(title: "Saved", message: "Your private key has been securely saved.")
        } catch {
            showAlert(title: "Error", message: "Failed to save the private key to the Keychain.")
        }
    }
    
    private func eraseAndSave() {
        privateTextView.text = ""
        do {
            try KeychainHelper.shared.save(key: keychainKey, value: "")
            showAlert(title: "Erased", message: "Your private key has been erased and saved.")
        } catch {
            showAlert(title: "Error", message: "Failed to erase the private key.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}
