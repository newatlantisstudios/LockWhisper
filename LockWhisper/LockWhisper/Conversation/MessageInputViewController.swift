import UIKit
import ObjectivePGP

class MessageInputViewController: UIViewController {
    
    var contact: Contact?
    weak var delegate: MessageInputDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Decrypt, Encrypt, and Add Message"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.font = .systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let decryptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Decrypt", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let decryptAndAddButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Decrypt and Add", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let encryptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Encrypt", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(textView)
        view.addSubview(decryptButton)
        view.addSubview(decryptAndAddButton)
        view.addSubview(encryptButton)
        
        updateInterfaceColors()
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            decryptButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            decryptButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            decryptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            decryptButton.heightAnchor.constraint(equalToConstant: 44),
            
            decryptAndAddButton.topAnchor.constraint(equalTo: decryptButton.bottomAnchor, constant: 12),
            decryptAndAddButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            decryptAndAddButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            decryptAndAddButton.heightAnchor.constraint(equalToConstant: 44),
            
            encryptButton.topAnchor.constraint(equalTo: decryptAndAddButton.bottomAnchor, constant: 12),
            encryptButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            encryptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            encryptButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        decryptButton.addTarget(self, action: #selector(decryptTapped), for: .touchUpInside)
        decryptAndAddButton.addTarget(self, action: #selector(decryptAndAddTapped), for: .touchUpInside)
        encryptButton.addTarget(self, action: #selector(encryptTapped), for: .touchUpInside)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateInterfaceColors()
        }
    }
    
    private func updateInterfaceColors() {
        // Update text colors
        titleLabel.textColor = .label
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        
        // Update border colors
        textView.layer.borderColor = UIColor.separator.cgColor
        
        // Update button colors while maintaining their distinct appearances
        decryptButton.backgroundColor = .systemBlue
        decryptAndAddButton.backgroundColor = .systemBlue
        encryptButton.backgroundColor = .systemGreen
        
        // Ensure button text remains visible in both modes
        decryptButton.setTitleColor(.white, for: .normal)
        decryptAndAddButton.setTitleColor(.white, for: .normal)
        encryptButton.setTitleColor(.white, for: .normal)
    }
    
    @objc private func decryptTapped() {
        guard let encryptedText = textView.text, !encryptedText.isEmpty else {
            showError(message: "Please enter encrypted text to decrypt")
            return
        }
        
        do {
            guard let privateKey = try KeychainHelper.shared.get(key: "privatePGPKey") else {
                showError(message: "Private key not found")
                return
            }
            
            let keyData = privateKey.data(using: .utf8)!
            let key = try ObjectivePGP.readKeys(from: keyData).first!
            
            // Check if key is encrypted (needs passphrase)
            if key.isEncryptedWithPassword {
                showPassphrasePrompt(forKey: key, encryptedText: encryptedText)
            } else {
                // Decrypt without passphrase
                decryptMessage(withKey: key, encryptedText: encryptedText, passphrase: nil)
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    private func showPassphrasePrompt(forKey key: Key, encryptedText: String) {
        let passphraseAlert = UIAlertController(title: "Enter Passphrase", message: nil, preferredStyle: .alert)
        passphraseAlert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Enter your private key passphrase"
        }
        
        let decryptAction = UIAlertAction(title: "Decrypt", style: .default) { [weak self] _ in
            guard let passphrase = passphraseAlert.textFields?.first?.text else { return }
            self?.decryptMessage(withKey: key, encryptedText: encryptedText, passphrase: passphrase)
        }
        
        passphraseAlert.addAction(decryptAction)
        passphraseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(passphraseAlert, animated: true)
    }
    
    private func decryptMessage(withKey key: Key, encryptedText: String, passphrase: String?) {
        do {
            var verified: Int32 = 0
            var decryptionError: NSError?
            
            let encryptedData = encryptedText.data(using: .utf8)!
            let decryptedData = try ObjectivePGP.decrypt(encryptedData,
                                                         verified: &verified,
                                                         certifyWithRootKey: false,
                                                         using: [key],
                                                         passphraseForKey: { _ in
                return passphrase
            },
                                                         decryptionError: &decryptionError)
            
            if let error = decryptionError {
                throw error
            }
            
            if let decryptedText = String(data: decryptedData, encoding: .utf8) {
                textView.text = decryptedText
            } else {
                showError(message: "Could not decode decrypted data")
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func encryptTapped() {
        guard let messageText = textView.text, !messageText.isEmpty else {
            showError(message: "Please enter text to encrypt")
            return
        }
        
        guard let contact = self.contact else {
            showError(message: "Contact not found")
            return
        }
        
        do {
            let messageData = messageText.data(using: .utf8)!
            let publicKeyData = contact.publicKey.data(using: .utf8)!
            let publicKey = try ObjectivePGP.readKeys(from: publicKeyData).first!
            
            let encryptedData = try ObjectivePGP.encrypt(messageData,
                                                         addSignature: false,
                                                         using: [publicKey])
            
            let armoredMessage = Armor.armored(encryptedData, as: .message)
            textView.text = armoredMessage
            
        } catch {
            showError(message: "Encryption error: \(error.localizedDescription)")
        }
    }
    
    @objc private func decryptAndAddTapped() {
        guard let encryptedText = textView.text, !encryptedText.isEmpty else {
            showError(message: "Please enter encrypted text to decrypt")
            return
        }
        
        do {
            guard let privateKey = try KeychainHelper.shared.get(key: "privatePGPKey") else {
                showError(message: "Private key not found")
                return
            }
            
            let keyData = privateKey.data(using: .utf8)!
            let key = try ObjectivePGP.readKeys(from: keyData).first!
            
            // Check if key is encrypted (needs passphrase)
            if key.isEncryptedWithPassword {
                showPassphrasePromptAndAdd(forKey: key, encryptedText: encryptedText)
            } else {
                // Decrypt without passphrase and add
                decryptMessageAndAdd(withKey: key, encryptedText: encryptedText, passphrase: nil)
            }
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    private func showPassphrasePromptAndAdd(forKey key: Key, encryptedText: String) {
        let passphraseAlert = UIAlertController(title: "Enter Passphrase", message: nil, preferredStyle: .alert)
        passphraseAlert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Enter your private key passphrase"
        }
        
        let decryptAction = UIAlertAction(title: "Decrypt and Add", style: .default) { [weak self] _ in
            guard let passphrase = passphraseAlert.textFields?.first?.text else { return }
            self?.decryptMessageAndAdd(withKey: key, encryptedText: encryptedText, passphrase: passphrase)
        }
        
        passphraseAlert.addAction(decryptAction)
        passphraseAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(passphraseAlert, animated: true)
    }
    
    private func decryptMessageAndAdd(withKey key: Key, encryptedText: String, passphrase: String?) {
        var verified: Int32 = 0
        var decryptionError: NSError?
        
        let encryptedData = encryptedText.data(using: .utf8)!
        let decryptedData: Data
        let decryptedText: String
        
        // First try block: PGP Decryption
        do {
            decryptedData = try ObjectivePGP.decrypt(encryptedData,
                                                     verified: &verified,
                                                     certifyWithRootKey: false,
                                                     using: [key],
                                                     passphraseForKey: { _ in
                return passphrase
            },
                                                     decryptionError: &decryptionError)
            
            if let error = decryptionError {
                let errorMessage = error.localizedDescription
                if errorMessage.contains("Incorrect key passphrase") {
                    showError(message: "Incorrect passphrase. Please try again.")
                } else if errorMessage.contains("No secret key") {
                    showError(message: "No matching secret key found for decryption")
                } else {
                    showError(message: "PGP Decryption failed: \(errorMessage)")
                }
                return
            }
        } catch let pgpError as NSError {
            if pgpError.domain == "ObjectivePGP" {
                switch pgpError.code {
                case -1:
                    showError(message: "Invalid PGP message format")
                case -2:
                    showError(message: "Message is not PGP encrypted")
                default:
                    showError(message: "PGP Error: \(pgpError.localizedDescription)")
                }
            } else {
                showError(message: "Decryption failed: \(pgpError.localizedDescription)")
            }
            return
        }
        
        // Convert decrypted data to string
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            showError(message: "Could not decode decrypted data")
            return
        }
        decryptedText = decryptedString
        
        // Add to UserDefaults
        guard let contact = self.contact else {
            showError(message: "Contact not found")
            return
        }
        
        if var contactsData = UserDefaults.standard.data(forKey: "contacts") {
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()
            
            do {
                var contacts = try decoder.decode([Contact].self, from: contactsData)
                if let index = contacts.firstIndex(where: { $0.name == contact.name }) {
                    contacts[index].messages.append(decryptedText)
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    contacts[index].messageDates.append(dateFormatter.string(from: Date()))
                    
                    do {
                        contactsData = try encoder.encode(contacts)
                        UserDefaults.standard.set(contactsData, forKey: "contacts")
                        print("Saved messages:", contacts[index].messages)
                        textView.text = decryptedText
                        delegate?.messageWasAdded()
                        dismiss(animated: true)
                    } catch {
                        showError(message: "Failed to save message: \(error.localizedDescription)")
                        return
                    }
                } else {
                    showError(message: "Contact not found in saved contacts")
                    return
                }
            } catch {
                showError(message: "Failed to load contacts: \(error.localizedDescription)")
                return
            }
        } else {
            showError(message: "No contacts data found")
            return
        }
    }
    
}


