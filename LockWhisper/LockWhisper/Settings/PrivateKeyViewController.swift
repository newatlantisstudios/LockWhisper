import UIKit
import LocalAuthentication

class PrivateKeyViewController: UIViewController {
    
    private let privateTextView = UITextView()
    private let keychainKey = "privatePGPKey"
    private let editButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    
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
        privateTextView.isEditable = false
        privateTextView.isScrollEnabled = true
        privateTextView.layer.borderColor = UIColor.systemGray.cgColor
        privateTextView.layer.borderWidth = 1
        privateTextView.layer.cornerRadius = 8
        privateTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(privateTextView)
        
        // Edit Button
        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        editButton.addTarget(self, action: #selector(enableEditing), for: .touchUpInside)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editButton)
        
        // Save Button
        saveButton.setTitle("Save to iOS keychain", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        saveButton.addTarget(self, action: #selector(savePrivateKey), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
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
            
            editButton.topAnchor.constraint(equalTo: privateTextView.bottomAnchor, constant: 20),
            editButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: privateTextView.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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
    
    @objc private func enableEditing() {
        privateTextView.isEditable = true
        editButton.isEnabled = false
    }
    
    @objc private func savePrivateKey() {
        guard let text = privateTextView.text, !text.isEmpty else {
            showAlert(title: "Error", message: "Private key cannot be empty.")
            return
        }
        
        do {
            try KeychainHelper.shared.save(key: keychainKey, value: text)
            showAlert(title: "Saved", message: "Your private key has been securely saved.")
            privateTextView.isEditable = false
            editButton.isEnabled = true
        } catch {
            showAlert(title: "Error", message: "Failed to save the private key to the Keychain.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
