import LocalAuthentication
import UIKit
import UniformTypeIdentifiers

class PGPSettingsViewController: UIViewController, UIDocumentPickerDelegate {

    private let textView = UITextView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let userDefaultsKey = Constants.publicPGPKey
    private let keychainKey = Constants.publicPGPKey
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
        migratePGPPublicKeyIfNeeded()
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

    private func migratePGPPublicKeyIfNeeded() {
        // If key exists in UserDefaults but not in Keychain, migrate it
        if let savedKey = UserDefaults.standard.string(forKey: userDefaultsKey),
           (try? KeychainHelper.shared.get(key: keychainKey)) == nil {
            do {
                try KeychainHelper.shared.save(key: keychainKey, value: savedKey)
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            } catch {
                print("Failed to migrate PGP public key to Keychain: \(error)")
            }
        }
    }

    private func loadPGPKey() {
        do {
            if let savedKey = try KeychainHelper.shared.get(key: keychainKey) {
                // Check if it's encrypted
                if PGPEncryptionManager.shared.isEncryptedBase64String(savedKey) {
                    let decryptedKey = try PGPEncryptionManager.shared.decryptBase64ToString(savedKey)
                    textView.text = decryptedKey
                } else {
                    textView.text = savedKey
                }
            } else {
                textView.text = "No PGP key found."
            }
        } catch {
            print("Failed to load PGP key: \(error.localizedDescription)")
            textView.text = "Error loading key: \(error.localizedDescription)"
        }
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
                    let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(text)
                    try KeychainHelper.shared.save(key: self.keychainKey, value: encryptedKey)
                    self.showAlert(
                        title: "Success",
                        message:
                            "Your PGP key has been saved securely with encryption."
                    )
                } catch {
                    do {
                        try KeychainHelper.shared.save(key: self.keychainKey, value: text)
                        self.showAlert(
                            title: "Warning",
                            message:
                                "Your PGP key has been saved, but without additional encryption: \(error.localizedDescription)"
                        )
                    } catch {
                        self.showAlert(
                            title: "Error",
                            message:
                                "Failed to save the PGP key: \(error.localizedDescription)"
                        )
                    }
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
                do {
                    try KeychainHelper.shared.delete(key: self?.keychainKey ?? "")
                } catch {}
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
                if let publicKey = try KeychainHelper.shared.get(key: keychainKey) {
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
        let keyGenVC = PGPKeyGenerationViewController()
        keyGenVC.delegate = self
        keyGenVC.modalPresentationStyle = .formSheet
        present(keyGenVC, animated: true)
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
                try KeychainHelper.shared.save(key: self.keychainKey, value: fileContents)
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

// Add delegate conformance
extension PGPSettingsViewController: PGPKeyGenerationDelegate {
    func didRequestKeyGeneration(name: String, email: String, passphrase: String) {
        dismiss(animated: true) {
            self.generatePGPKeyPair(name: name, email: email, passphrase: passphrase)
        }
    }
    func didCancelKeyGeneration() {
        dismiss(animated: true)
    }
    private func generatePGPKeyPair(name: String, email: String, passphrase: String) {
        Task {
            do {
                let (publicKey, privateKey) = try await PGPWebView.shared.makePGPKeyPair(name: name, email: email, passphrase: passphrase)
                try KeychainHelper.shared.save(key: "privatePGPKey", value: privateKey)
                try KeychainHelper.shared.save(key: self.keychainKey, value: publicKey)
                DispatchQueue.main.async {
                    self.textView.text = publicKey
                    self.showAlert(title: "Success", message: "PGP key pair generated successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to generate key pair: \(error.localizedDescription)")
                }
            }
        }
    }
}
