import UIKit

class MessageInputViewController: UIViewController {

    var contact: ContactPGP?
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

    private let addPlainTextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Plain Text", for: .normal)
        button.backgroundColor = .systemOrange
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
        view.addSubview(addPlainTextButton)

        updateInterfaceColors()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),

            textView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),

            decryptButton.topAnchor.constraint(
                equalTo: textView.bottomAnchor, constant: 20),
            decryptButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            decryptButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            decryptButton.heightAnchor.constraint(equalToConstant: 44),

            decryptAndAddButton.topAnchor.constraint(
                equalTo: decryptButton.bottomAnchor, constant: 12),
            decryptAndAddButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            decryptAndAddButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            decryptAndAddButton.heightAnchor.constraint(equalToConstant: 44),

            encryptButton.topAnchor.constraint(
                equalTo: decryptAndAddButton.bottomAnchor, constant: 12),
            encryptButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            encryptButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            encryptButton.heightAnchor.constraint(equalToConstant: 44),

            addPlainTextButton.topAnchor.constraint(
                equalTo: encryptButton.bottomAnchor, constant: 12),
            addPlainTextButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            addPlainTextButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            addPlainTextButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func setupActions() {
        decryptButton.addTarget(
            self, action: #selector(decryptTapped), for: .touchUpInside)
        decryptAndAddButton.addTarget(
            self, action: #selector(decryptAndAddTapped), for: .touchUpInside)
        encryptButton.addTarget(
            self, action: #selector(encryptTapped), for: .touchUpInside)
        addPlainTextButton.addTarget(
            self, action: #selector(addPlainTextTapped), for: .touchUpInside)
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(
            comparedTo: previousTraitCollection)
        {
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

    @objc private func addPlainTextTapped() {
        guard let plainText = textView.text, !plainText.isEmpty else {
            showError(message: "Please enter text to add")
            return
        }

        guard let contact = self.contact else {
            showError(message: "Contact not found")
            return
        }

        Task {
            // Get all contacts using our helper method instead of the property
            var contacts = PGPEncryptionManager.shared.getContacts()

            if let index = contacts.firstIndex(where: {
                $0.name == contact.name
            }) {
                // Append the plain text message
                contacts[index].messages.append(plainText)

                // Append the current date as a string
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                contacts[index].messageDates.append(
                    dateFormatter.string(from: Date()))

                // Save using the computed property which handles encryption
                UserDefaults.standard.contacts = contacts

                print("Saved plain text message: \(plainText)")

                await MainActor.run {
                    self.delegate?.messageWasAdded()
                    self.dismiss(animated: true)
                }
            } else {
                await MainActor.run {
                    self.showError(
                        message: "Contact not found in saved contacts")
                }
            }
        }
    }

    @objc private func decryptTapped() {
        guard let encryptedText = textView.text, !encryptedText.isEmpty else {
            showError(message: "Please enter encrypted text to decrypt")
            return
        }

        Task {
            do {
                guard
                    let privateKey = try KeychainHelper.shared.get(
                        key: "privatePGPKey")
                else {
                    await MainActor.run {
                        showError(message: "Private key not found")
                    }
                    return
                }

                let isEncrypted = try await PGPWebView.shared.isKeyEncrypted(
                    privateKey)
                print("isEncrypted: \(isEncrypted)")

                await MainActor.run {
                    if isEncrypted {
                        showPassphrasePrompt(encryptedText: encryptedText)
                    } else {
                        decryptMessage(
                            encryptedText: encryptedText, passphrase: nil)
                    }
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    private func showPassphrasePrompt(encryptedText: String) {
        let alert = UIAlertController(
            title: "Enter Passphrase", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Enter your private key passphrase"
        }

        let decryptAction = UIAlertAction(title: "Decrypt", style: .default) {
            [weak self] _ in
            guard let passphrase = alert.textFields?.first?.text else { return }
            self?.decryptMessage(
                encryptedText: encryptedText, passphrase: passphrase)
        }

        alert.addAction(decryptAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func decryptMessage(encryptedText: String, passphrase: String?) {
        Task {
            do {
                guard
                    let privateKeyEncrypted = try KeychainHelper.shared.get(
                        key: "privatePGPKey")
                else {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Private key not found"
                        ])
                }

                // Decrypt the encrypted private key before using it
                let privateKey: String
                if PGPEncryptionManager.shared.isEncryptedBase64String(
                    privateKeyEncrypted)
                {
                    privateKey = try PGPEncryptionManager.shared
                        .decryptBase64ToString(privateKeyEncrypted)
                } else {
                    privateKey = privateKeyEncrypted
                }

                let decryptedText = try await PGPWebView.shared.decrypt(
                    encryptedText, withPrivateKey: privateKey,
                    passphrase: passphrase)

                await MainActor.run {
                    textView.text = decryptedText
                }
            } catch PGPError.needsPassphrase {
                await MainActor.run {
                    showPassphrasePrompt(encryptedText: encryptedText)
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error", message: message, preferredStyle: .alert)
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

        Task {
            do {
                print("Starting encryption")
                print("Message text length:", messageText.count)
                //print("Using public key:", contact.publicKey)

                let encryptedText = try await PGPWebView.shared.encrypt(
                    messageText, withPublicKey: contact.publicKey)
                print(
                    "Encryption succeeded, result length:", encryptedText.count)

                await MainActor.run {
                    textView.text = encryptedText
                }
            } catch {
                print("Encryption failed1:", error)
                await MainActor.run {
                    showError(
                        message:
                            "Encryption error: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func decryptAndAddTapped() {
        guard let encryptedText = textView.text, !encryptedText.isEmpty else {
            showError(message: "Please enter encrypted text to decrypt")
            return
        }

        Task {
            do {
                guard
                    let privateKey = try KeychainHelper.shared.get(
                        key: "privatePGPKey")
                else {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Private key not found"
                        ])
                }

                let isEncrypted = try await PGPWebView.shared.isKeyEncrypted(
                    privateKey)

                await MainActor.run {
                    if isEncrypted {
                        showPassphrasePromptAndAdd(encryptedText: encryptedText)
                    } else {
                        decryptMessageAndAdd(
                            encryptedText: encryptedText, passphrase: nil)
                    }
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }

    private func showPassphrasePromptAndAdd(encryptedText: String) {
        let alert = UIAlertController(
            title: "Enter Passphrase", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Enter your private key passphrase"
        }

        let decryptAction = UIAlertAction(
            title: "Decrypt and Add", style: .default
        ) { [weak self] _ in
            guard let passphrase = alert.textFields?.first?.text else { return }
            self?.decryptMessageAndAdd(
                encryptedText: encryptedText, passphrase: passphrase)
        }

        alert.addAction(decryptAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func decryptMessageAndAdd(encryptedText: String, passphrase: String?) {
        Task {
            do {
                guard let privateKeyEncrypted = try KeychainHelper.shared.get(key: "privatePGPKey") else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Private key not found"])
                }
                
                // Decrypt the encrypted private key before using it
                let privateKey: String
                if PGPEncryptionManager.shared.isEncryptedBase64String(privateKeyEncrypted) {
                    privateKey = try PGPEncryptionManager.shared.decryptBase64ToString(privateKeyEncrypted)
                } else {
                    privateKey = privateKeyEncrypted
                }

                let decryptedText = try await PGPWebView.shared.decrypt(
                    encryptedText, withPrivateKey: privateKey, passphrase: passphrase)

                guard let contact = self.contact else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Contact not found"])
                }

                await MainActor.run {
                    // Use our helper method instead of the property
                    var contacts = PGPEncryptionManager.shared.getContacts()
                    if let index = contacts.firstIndex(where: { $0.name == contact.name }) {
                        contacts[index].messages.append(decryptedText)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        contacts[index].messageDates.append(dateFormatter.string(from: Date()))
                        
                        // Use the setter which handles encryption
                        UserDefaults.standard.contacts = contacts
                        
                        self.textView.text = decryptedText
                        self.delegate?.messageWasAdded()
                        self.dismiss(animated: true)
                    } else {
                        self.showError(message: "Contact not found in saved contacts")
                    }
                }
            } catch PGPError.needsPassphrase {
                await MainActor.run {
                    self.showPassphrasePromptAndAdd(encryptedText: encryptedText)
                }
            } catch {
                await MainActor.run {
                    self.showError(message: error.localizedDescription)
                }
            }
        }
    }

}
