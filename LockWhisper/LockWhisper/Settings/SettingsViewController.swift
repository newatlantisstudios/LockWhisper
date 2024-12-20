import UIKit
import LocalAuthentication
import UniformTypeIdentifiers
import ObjectivePGP

class SettingsViewController: UIViewController, UIDocumentPickerDelegate {
    
    private let textView = UITextView()
    private let userDefaultsKey = "publicPGPKey"
    private let editButton = StyledButton()
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
        loadPGPKey() // Load the saved PGP key
    }
    
    private func setupUI() {
        // Label
        let label = UILabel()
        label.text = "My Public PGP Key"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center // Center the text
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // TextView
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false // Start as non-editable
        textView.isScrollEnabled = true
        textView.layer.borderColor = UIColor.systemGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        // Add to layout/UI setup
        let securityLabel = UILabel()
        securityLabel.text = "⚠️ Without Advanced Data Protection (ADP) enabled in iOS Settings > Apple ID > iCloud, Apple can access your PGP keys and encrypted messages through your iCloud backup. Enable ADP for end-to-end encryption."
        securityLabel.textColor = .systemRed
        securityLabel.font = .preferredFont(forTextStyle: .footnote)
        securityLabel.numberOfLines = 0
        securityLabel.textAlignment = .center
        
        // Buttons
        configureButton(editButton, title: "Edit", action: #selector(enableEditing), style: .secondary)
        configureButton(saveButton, title: "Save", action: #selector(savePGPKey))
        configureButton(airDropButton, title: "AirDrop", action: #selector(shareViaAirDrop), style: .secondary)
        configureButton(privateKeyButton, title: "Private PGP Key", action: #selector(showPrivateKeyView))
        configureButton(importButton, title: "Import PGP Keys", action: #selector(importPGPKeys))
        configureButton(makeKeyPairButton, title: "Make PGP Key Pair", action: #selector(makePGPKeyPair))
        configureButton(exportButton, title: "Export PGP Keys", action: #selector(exportPGPKeys))
        
        // Add buttons to the view
        view.addSubview(editButton)
        view.addSubview(saveButton)
        view.addSubview(airDropButton)
        view.addSubview(privateKeyButton)
        view.addSubview(importButton)
        view.addSubview(exportButton)
        view.addSubview(makeKeyPairButton)
        
        view.addSubview(securityLabel)
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // Label constraints
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor), // Center horizontally
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // TextView constraints
            textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 150),
            
            // Edit Button constraints
            editButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            editButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -20),
            
            // Save Button constraints
            saveButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // AirDrop Button constraints
            airDropButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            airDropButton.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 20),
            
            // Private Key Button constraints
            privateKeyButton.topAnchor.constraint(equalTo: airDropButton.bottomAnchor, constant: 20),
            privateKeyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Import Button constraints
            importButton.topAnchor.constraint(equalTo: privateKeyButton.bottomAnchor, constant: 20),
            importButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Export Button constraints - now below importButton
            exportButton.topAnchor.constraint(equalTo: importButton.bottomAnchor, constant: 20),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Make Key Pair Button constraints - now below exportButton
            makeKeyPairButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 20),
            makeKeyPairButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            securityLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            securityLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            securityLabel.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -16),
            
            // Update button constraints for better spacing and alignment
                editButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
                saveButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
                airDropButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
                privateKeyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
                importButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
                exportButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
                makeKeyPairButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)

        ])
    }
    
    private func configureButton(_ button: StyledButton, title: String, action: Selector, style: ButtonStyle = .primary) {
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setStyle(style)
    }
    
    @objc private func enableEditing() {
        textView.isEditable = true // Enable editing
        editButton.isEnabled = false // Disable Edit Button
    }
    
    private func loadPGPKey() {
        // Fetch the saved public PGP key from UserDefaults
        if let savedKey = UserDefaults.standard.string(forKey: userDefaultsKey) {
            textView.text = savedKey // Display the key in the textView
        } else {
            textView.text = "No PGP key found." // Default message if no key is saved
        }
    }
    
    @objc private func savePGPKey() {
        guard let text = textView.text else { return }
        UserDefaults.standard.set(text, forKey: userDefaultsKey)
        showAlert(title: "Saved", message: "Your PGP key has been saved locally.")
        
        // Disable editing and re-enable Edit Button
        textView.isEditable = false
        editButton.isEnabled = true
    }
    
    @objc private func exportPGPKeys() {
        let alert = UIAlertController(title: "Export PGP Keys",
                                      message: "Which keys would you like to export?",
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Public Key", style: .default) { [weak self] _ in
            self?.exportSelectedKeys(exportPublic: true, exportPrivate: false)
        })
        
        alert.addAction(UIAlertAction(title: "Private Key", style: .default) { [weak self] _ in
            self?.exportSelectedKeys(exportPublic: false, exportPrivate: true)
        })
        
        alert.addAction(UIAlertAction(title: "Both Keys", style: .default) { [weak self] _ in
            self?.exportSelectedKeys(exportPublic: true, exportPrivate: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = exportButton
            popoverController.sourceRect = exportButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func exportSelectedKeys(exportPublic: Bool, exportPrivate: Bool) {
        let confirmAlert = UIAlertController(title: "Confirm Export",
                                             message: "The keys will be saved in the app's document folder. Do you want to proceed?",
                                             preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Export", style: .default) { [weak self] _ in
            self?.performKeyExport(exportPublic: exportPublic, exportPrivate: exportPrivate)
        })
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(confirmAlert, animated: true)
    }
    
    private func performKeyExport(exportPublic: Bool, exportPrivate: Bool) {
        do {
            // Get the app group container directory
            let fileManager = FileManager.default
            guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                showAlert(title: "Error", message: "Could not access documents directory")
                return
            }
            
            // Create a custom directory for exported keys
            let keysDirectory = documentsPath.appendingPathComponent("ExportedKeys", isDirectory: true)
            try fileManager.createDirectory(at: keysDirectory, withIntermediateDirectories: true)
            
            var exportedFiles: [String] = []
            
            if exportPublic {
                if let publicKey = UserDefaults.standard.string(forKey: userDefaultsKey) {
                    let publicKeyPath = keysDirectory.appendingPathComponent("public_key.asc")
                    try publicKey.write(to: publicKeyPath, atomically: true, encoding: .utf8)
                    try (publicKeyPath as NSURL).setResourceValue(true, forKey: .isUbiquitousItemKey)
                    exportedFiles.append("public_key.asc")
                }
            }
            
            if exportPrivate {
                if let privateKey = try KeychainHelper.shared.get(key: "privatePGPKey") {
                    let privateKeyPath = keysDirectory.appendingPathComponent("private_key.asc")
                    try privateKey.write(to: privateKeyPath, atomically: true, encoding: .utf8)
                    try (privateKeyPath as NSURL).setResourceValue(true, forKey: .isUbiquitousItemKey)
                    exportedFiles.append("private_key.asc")
                }
            }
            
            if !exportedFiles.isEmpty {
                showAlert(title: "Success",
                          message: "Files exported to ExportedKeys folder:\n\(exportedFiles.joined(separator: ", "))")
            } else {
                showAlert(title: "Error", message: "No keys were available to export")
            }
            
        } catch {
            showAlert(title: "Error", message: "Failed to export keys: \(error.localizedDescription)")
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
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.postToFacebook, .postToTwitter]
        present(activityVC, animated: true, completion: nil)
    }
    
    @objc private func showPrivateKeyView() {
        let authContext = LAContext()
        var error: NSError?
        
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Access your private PGP key") { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        let privateKeyVC = PrivateKeyViewController()
                        self?.navigationController?.pushViewController(privateKeyVC, animated: true)
                    } else {
                        self?.showAlert(title: "Authentication Failed", message: "Could not verify your identity.")
                    }
                }
            }
        } else {
            showAlert(title: "Biometrics Not Available", message: "Your device does not support Face ID or Touch ID.")
        }
    }
    
    @objc private func importPGPKeys() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .text])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc private func makePGPKeyPair() {
        promptForKeyDetails { name, email, passphrase in
            do {
                let uid = "\(name) <\(email)>"
                
                let key = KeyGenerator().generate(for: uid, passphrase: passphrase)
                
                let privateKeyData = try key.export(keyType: .secret)
                let armoredPrivateKey = Armor.armored(privateKeyData, as: .secretKey)
                let armoredPublicKey = Armor.armored(try key.export(keyType: .public), as: .publicKey)
                
                // Save private key to Keychain
                try KeychainHelper.shared.save(key: "privatePGPKey", value: armoredPrivateKey)
                
                // Save public key to UserDefaults
                UserDefaults.standard.set(armoredPublicKey, forKey: "publicPGPKey")
                
                // Update the TextView with the new public key
                self.textView.text = armoredPublicKey
                
                self.showAlert(title: "Success", message: "PGP key pair generated successfully.")
            } catch {
                self.showAlert(title: "Error", message: "Failed to generate PGP key pair: \(error.localizedDescription)")
            }
        }
    }
    
    private func promptForKeyDetails(completion: @escaping (String, String, String) -> Void) {
        let alertController = UIAlertController(title: "Generate PGP Key Pair", message: "Enter your details to generate a PGP key pair.", preferredStyle: .alert)
        
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
        let generateAction = UIAlertAction(title: "Generate", style: .default) { _ in
            // Retrieve user input
            guard let name = alertController.textFields?[0].text, !name.isEmpty,
                  let email = alertController.textFields?[1].text, !email.isEmpty,
                  let passphrase = alertController.textFields?[2].text, !passphrase.isEmpty else {
                self.showAlert(title: "Error", message: "All fields are required.")
                return
            }
            completion(name, email, passphrase)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(generateAction)
        alertController.addAction(cancelAction)
        
        // Present the alert
        present(alertController, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        
        do {
            let fileContents = try String(contentsOf: selectedFileURL, encoding: .utf8)
            
            var message = "Imported Key:\n"
            
            if fileContents.contains("PRIVATE KEY") {
                // Save private key using PrivateKeyViewController method
                try KeychainHelper.shared.save(key: "privatePGPKey", value: fileContents)
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
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
