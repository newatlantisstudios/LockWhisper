import LocalAuthentication
import UIKit
import UniformTypeIdentifiers

class PGPSettingsViewController: UIViewController, UIDocumentPickerDelegate {

    private let textView = UITextView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let userDefaultsKey = "publicPGPKey"
    private let eraseButton = StyledButton()
    private let saveButton = StyledButton()
    private let airDropButton = StyledButton()
    private let privateKeyButton = StyledButton()
    private let importButton = StyledButton()
    private let makeKeyPairButton = StyledButton()
    private let exportButton = StyledButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        view.backgroundColor = .systemBackground

        setupUI()
        loadPGPKey()  // Load the saved PGP key
    }

    private func setupUI() {
        // Setup ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Setup ContentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Label
        let label = UILabel()
        label.text = "My Public PGP Key"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        // TextView and other UI elements setup remains the same, but add to contentView instead of view
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.layer.borderColor = UIColor.systemGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)

        // Security warning label
        let securityLabel = UILabel()
        securityLabel.text =
            "⚠️ Without Advanced Data Protection (ADP) enabled in iOS Settings > Apple ID > iCloud, Apple can access your PGP keys and encrypted messages through your iCloud backup. Enable ADP for end-to-end encryption.⚠️"
        securityLabel.textColor = .systemRed
        securityLabel.font = .preferredFont(forTextStyle: .footnote)
        securityLabel.numberOfLines = 0
        securityLabel.textAlignment = .center
        securityLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure and add buttons to contentView
        configureButton(
            eraseButton, title: "Erase and Save",
            action: #selector(erasePGPKey), style: .warning)
        configureButton(
            saveButton, title: "Save", action: #selector(savePGPKey))
        configureButton(
            airDropButton, title: "AirDrop", action: #selector(shareViaAirDrop),
            style: .secondary)
        configureButton(
            privateKeyButton, title: "Private PGP Key",
            action: #selector(showPrivateKeyView))
        configureButton(
            importButton, title: "Import PGP Keys",
            action: #selector(importPGPKeys))
        configureButton(
            exportButton, title: "Export PGP Keys",
            action: #selector(exportPGPKeys))
        configureButton(
            makeKeyPairButton, title: "Make PGP Key Pair",
            action: #selector(makePGPKeyPair))

        [
            eraseButton, saveButton, airDropButton, privateKeyButton,
            importButton,
            exportButton, makeKeyPairButton, securityLabel,
        ].forEach { contentView.addSubview($0) }

        // Setup constraints
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // UI Elements constraints remain similar but reference contentView instead of view
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 20),
            label.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),

            textView.topAnchor.constraint(
                equalTo: label.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 150),

            // Button constraints
            eraseButton.topAnchor.constraint(
                equalTo: textView.bottomAnchor, constant: 20),
            eraseButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            eraseButton.widthAnchor.constraint(equalToConstant: 200),

            saveButton.topAnchor.constraint(
                equalTo: eraseButton.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),

            airDropButton.topAnchor.constraint(
                equalTo: saveButton.bottomAnchor, constant: 20),
            airDropButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            airDropButton.widthAnchor.constraint(equalToConstant: 200),

            privateKeyButton.topAnchor.constraint(
                equalTo: airDropButton.bottomAnchor, constant: 20),
            privateKeyButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            privateKeyButton.widthAnchor.constraint(equalToConstant: 200),

            importButton.topAnchor.constraint(
                equalTo: privateKeyButton.bottomAnchor, constant: 20),
            importButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            importButton.widthAnchor.constraint(equalToConstant: 200),

            exportButton.topAnchor.constraint(
                equalTo: importButton.bottomAnchor, constant: 20),
            exportButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            exportButton.widthAnchor.constraint(equalToConstant: 200),

            makeKeyPairButton.topAnchor.constraint(
                equalTo: exportButton.bottomAnchor, constant: 20),
            makeKeyPairButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            makeKeyPairButton.widthAnchor.constraint(equalToConstant: 200),

            securityLabel.topAnchor.constraint(
                equalTo: makeKeyPairButton.bottomAnchor, constant: 20),
            securityLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            securityLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),
            securityLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    @objc private func showTipJar() {
        let tipJarVC = TipJarViewController()
        navigationController?.pushViewController(tipJarVC, animated: true)
    }

    private func configureButton(
        _ button: StyledButton, title: String, action: Selector,
        style: ButtonStyle = .primary
    ) {
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setStyle(style)
    }

    private func loadPGPKey() {
        loadPGPKeyWithEncryption()
    }

    // New method that uses encryption
    private func loadPGPKeyWithEncryption() {
        do {
            // Attempt to load from UserDefaults
            if let savedKey = UserDefaults.standard.string(
                forKey: userDefaultsKey)
            {
                // Check if it's encrypted
                if PGPEncryptionManager.shared.isEncryptedBase64String(savedKey)
                {
                    // Decrypt and display
                    let decryptedKey = try PGPEncryptionManager.shared
                        .decryptBase64ToString(savedKey)
                    textView.text = decryptedKey
                } else {
                    // Legacy unencrypted key, display as is
                    textView.text = savedKey

                    // Migrate to encrypted storage if it looks like a valid key
                    if !savedKey.isEmpty && savedKey != "No PGP key found."
                        && savedKey.contains(
                            "-----BEGIN PGP PUBLIC KEY BLOCK-----")
                    {
                        try migrateToCryptoKit(savedKey)
                    }
                }
            } else {
                textView.text = "No PGP key found."
            }
        } catch {
            print("Failed to load PGP key: \(error.localizedDescription)")
            textView.text = "Error loading key: \(error.localizedDescription)"
        }
    }

    private func migrateToCryptoKit(_ key: String) throws {
        // Encrypt the key
        let encryptedKey = try PGPEncryptionManager.shared
            .encryptStringToBase64(key)

        // Save back to UserDefaults
        UserDefaults.standard.set(encryptedKey, forKey: userDefaultsKey)
        print("Successfully migrated public key to CryptoKit encryption")
    }

    @objc private func savePGPKey() {
        guard let text = textView.text, !text.isEmpty else { return }

        let alert = UIAlertController(
            title: "Save PGP Key",
            message:
                "Are you sure you want to save this PGP key? This will overwrite any existing key.",
            preferredStyle: .alert)

        alert.addAction(
            UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let self = self else { return }

                do {
                    // Encrypt the key before saving
                    let encryptedKey = try PGPEncryptionManager.shared
                        .encryptStringToBase64(text)
                    UserDefaults.standard.set(
                        encryptedKey, forKey: self.userDefaultsKey)

                    self.showAlert(
                        title: "Success",
                        message:
                            "Your PGP key has been saved locally with encryption."
                    )
                } catch {
                    // Fallback to unencrypted if encryption fails
                    UserDefaults.standard.set(
                        text, forKey: self.userDefaultsKey)

                    self.showAlert(
                        title: "Warning",
                        message:
                            "Your PGP key has been saved, but without additional encryption: \(error.localizedDescription)"
                    )
                }
            })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func erasePGPKey() {
        let alert = UIAlertController(
            title: "Erase PGP Key",
            message:
                "Are you sure you want to erase your public PGP key? This action cannot be undone.",
            preferredStyle: .alert)

        alert.addAction(
            UIAlertAction(title: "Erase", style: .destructive) {
                [weak self] _ in
                UserDefaults.standard.removeObject(
                    forKey: self?.userDefaultsKey ?? "")
                self?.textView.text = "No PGP key found."
                self?.showAlert(
                    title: "Success",
                    message: "Your public PGP key has been erased.")
            })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func exportPGPKeys() {
        let alert = UIAlertController(
            title: "Export PGP Keys",
            message: "Which keys would you like to export?",
            preferredStyle: .actionSheet)

        alert.addAction(
            UIAlertAction(title: "Public Key", style: .default) {
                [weak self] _ in
                self?.exportSelectedKeys(
                    exportPublic: true, exportPrivate: false)
            })

        alert.addAction(
            UIAlertAction(title: "Private Key", style: .default) {
                [weak self] _ in
                self?.exportSelectedKeys(
                    exportPublic: false, exportPrivate: true)
            })

        alert.addAction(
            UIAlertAction(title: "Both Keys", style: .default) {
                [weak self] _ in
                self?.exportSelectedKeys(
                    exportPublic: true, exportPrivate: true)
            })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = exportButton
            popoverController.sourceRect = exportButton.bounds
        }

        present(alert, animated: true)
    }

    private func exportSelectedKeys(exportPublic: Bool, exportPrivate: Bool) {
        let confirmAlert = UIAlertController(
            title: "Confirm Export",
            message:
                "The keys will be saved in the app's document folder. Do you want to proceed?",
            preferredStyle: .alert)

        confirmAlert.addAction(
            UIAlertAction(title: "Export", style: .default) { [weak self] _ in
                self?.performKeyExport(
                    exportPublic: exportPublic, exportPrivate: exportPrivate)
            })

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(confirmAlert, animated: true)
    }

    private func performKeyExport(exportPublic: Bool, exportPrivate: Bool) {
        // If exporting private key, require FaceID authentication
        if exportPrivate {
            let authContext = LAContext()
            var error: NSError?

            if authContext.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, error: &error)
            {
                authContext.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason:
                        "Authenticate to export your private PGP key"
                ) { [weak self] success, authError in
                    DispatchQueue.main.async {
                        if success {
                            self?.proceedWithKeyExport(
                                exportPublic: exportPublic,
                                exportPrivate: exportPrivate)
                        } else {
                            self?.showAlert(
                                title: "Authentication Failed",
                                message: "Could not verify your identity.")
                        }
                    }
                }
            } else {
                showAlert(
                    title: "Biometrics Not Available",
                    message: "Your device does not support Face ID or Touch ID."
                )
            }
        } else {
            // If only exporting public key, proceed without authentication
            proceedWithKeyExport(
                exportPublic: exportPublic, exportPrivate: exportPrivate)
        }
    }

    private func proceedWithKeyExport(exportPublic: Bool, exportPrivate: Bool) {
        do {
            // Get the app group container directory
            let fileManager = FileManager.default
            guard
                let documentsPath = fileManager.urls(
                    for: .documentDirectory, in: .userDomainMask
                ).first
            else {
                showAlert(
                    title: "Error",
                    message: "Could not access documents directory")
                return
            }

            // Create a custom directory for exported keys
            let keysDirectory = documentsPath.appendingPathComponent(
                "ExportedKeys", isDirectory: true)
            try fileManager.createDirectory(
                at: keysDirectory, withIntermediateDirectories: true)

            var exportedFiles: [String] = []

            if exportPublic {
                if let publicKey = UserDefaults.standard.string(
                    forKey: userDefaultsKey)
                {
                    let publicKeyPath = keysDirectory.appendingPathComponent(
                        "public_key.asc")
                    try publicKey.write(
                        to: publicKeyPath, atomically: true, encoding: .utf8)
                    try (publicKeyPath as NSURL).setResourceValue(
                        true, forKey: .isUbiquitousItemKey)
                    exportedFiles.append("public_key.asc")
                }
            }

            if exportPrivate {
                if let privateKey = try KeychainHelper.shared.get(
                    key: "privatePGPKey")
                {
                    let privateKeyPath = keysDirectory.appendingPathComponent(
                        "private_key.asc")
                    try privateKey.write(
                        to: privateKeyPath, atomically: true, encoding: .utf8)
                    try (privateKeyPath as NSURL).setResourceValue(
                        true, forKey: .isUbiquitousItemKey)
                    exportedFiles.append("private_key.asc")
                }
            }

            if !exportedFiles.isEmpty {
                showAlert(
                    title: "Success",
                    message:
                        "Files exported to ExportedKeys folder:\n\(exportedFiles.joined(separator: ", "))"
                )
            } else {
                showAlert(
                    title: "Error", message: "No keys were available to export")
            }

        } catch {
            showAlert(
                title: "Error",
                message: "Failed to export keys: \(error.localizedDescription)")
        }
    }

    @objc private func shareViaAirDrop() {
        guard let pgpKey = textView.text, !pgpKey.isEmpty else {
            showAlert(title: "Error", message: "No PGP key to share.")
            return
        }

        // Save the PGP key to a temporary file
        let tempURL = savePGPKeyToTemporaryFile(pgpKey: pgpKey)

        // Present the AirDrop sharing interface
        let activityVC = UIActivityViewController(
            activityItems: [tempURL], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.postToFacebook, .postToTwitter]
        present(activityVC, animated: true, completion: nil)
    }

    @objc private func showPrivateKeyView() {
        let authContext = LAContext()
        var error: NSError?

        if authContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &error)
        {
            authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access your private PGP key"
            ) { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        let privateKeyVC = PrivateKeyViewController()
                        self?.navigationController?.pushViewController(
                            privateKeyVC, animated: true)
                    } else {
                        self?.showAlert(
                            title: "Authentication Failed",
                            message: "Could not verify your identity.")
                    }
                }
            }
        } else {
            showAlert(
                title: "Biometrics Not Available",
                message: "Your device does not support Face ID or Touch ID.")
        }
    }

    @objc private func importPGPKeys() {
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.data, .text])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    func jsEscaped(_ input: String) -> String {
        // Very simple example; you could also
        // replace backslashes, newlines, etc.
        return input.replacingOccurrences(of: "'", with: "\\'")
    }

    @objc private func makePGPKeyPair() {
        promptForKeyDetails { [weak self] name, email, passphrase in
            guard let self = self else { return }

            Task {
                do {
                    let (publicKey, privateKey) = try await PGPWebView.shared
                        .makePGPKeyPair(
                            name: name,
                            email: email,
                            passphrase: passphrase
                        )

                    // Save keys
                    try KeychainHelper.shared.save(
                        key: "privatePGPKey", value: privateKey)
                    UserDefaults.standard.set(
                        publicKey, forKey: self.userDefaultsKey)

                    DispatchQueue.main.async {
                        self.textView.text = publicKey
                        self.showAlert(
                            title: "Success",
                            message: "PGP key pair generated successfully")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(
                            title: "Error",
                            message:
                                "Failed to generate key pair: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }

    private func promptForKeyDetails(
        completion: @escaping (String, String, String) -> Void
    ) {
        let alertController = UIAlertController(
            title: "Generate PGP Key Pair",
            message: "Enter your details to generate a PGP key pair.",
            preferredStyle: .alert)

        // Add text fields for name, email, and passphrase
        alertController.addTextField { textField in
            textField.placeholder = "Name (e.g., John Doe)"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Email (e.g., johndoe@example.com)"
            textField.keyboardType = .emailAddress
        }
        alertController.addTextField { textField in
            textField.placeholder = "Passphrase"
            textField.isSecureTextEntry = true
        }

        // Add actions
        let generateAction = UIAlertAction(title: "Generate", style: .default) {
            _ in
            // Retrieve user input
            guard var name = alertController.textFields?[0].text, !name.isEmpty,
                var email = alertController.textFields?[1].text, !email.isEmpty,
                var passphrase = alertController.textFields?[2].text,
                !passphrase.isEmpty
            else {
                self.showAlert(
                    title: "Error", message: "All fields are required.")
                return
            }
            completion(name, email, passphrase)
        }

        let cancelAction = UIAlertAction(
            title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(generateAction)
        alertController.addAction(cancelAction)

        // Present the alert
        present(alertController, animated: true, completion: nil)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        guard let selectedFileURL = urls.first else { return }

        do {
            let fileContents = try String(
                contentsOf: selectedFileURL, encoding: .utf8)

            var message = "Imported Key:\n"

            if fileContents.contains("PRIVATE KEY") {
                // Save private key using PrivateKeyViewController method
                try KeychainHelper.shared.save(
                    key: "privatePGPKey", value: fileContents)
                message += "- Private Key\n"
            }

            if fileContents.contains("PUBLIC KEY") {
                // Save public key to UserDefaults
                UserDefaults.standard.set(fileContents, forKey: "publicPGPKey")
                message += "- Public Key\n"
            }

            showAlert(title: "Success", message: message)
        } catch {
            showAlert(title: "Error", message: "Failed to read the PGP file.")
        }
    }

    private func savePGPKeyToTemporaryFile(pgpKey: String) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("publicPGPKey.asc")

        do {
            try pgpKey.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            showAlert(title: "Error", message: "Failed to save PGP key.")
        }

        return fileURL
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(
            title: title, message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
