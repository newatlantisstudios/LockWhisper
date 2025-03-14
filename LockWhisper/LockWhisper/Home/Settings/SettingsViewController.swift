// Define error types only for our internal use (these won't conflict with existing types)
enum MigrationCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

enum MigrationKeychainError: Error {
    case unhandledError(status: OSStatus)
}

import UIKit
import LocalAuthentication
import ZipArchive
import CryptoKit
import CoreData

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    // A switch to toggle biometric authentication.
    private let biometricSwitch: UISwitch = {
       let biometricSwitch = UISwitch()
       biometricSwitch.translatesAutoresizingMaskIntoConstraints = false
       biometricSwitch.isOn = UserDefaults.standard.bool(forKey: "biometricEnabled")
       return biometricSwitch
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Settings"
        setupNavigationBar()
        setupLockWhisperLabel()
        setupBiometricSwitch()
        setupMigrationButtons() // Add migration buttons
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBar() {
        // Create the tip jar button using the image named "tipJar"
        let tipJarImage = UIImage(named: "tipJar")
        let tipJarButton = UIBarButtonItem(image: tipJarImage, style: .plain, target: self, action: #selector(tipJarTapped))
        navigationItem.rightBarButtonItem = tipJarButton
    }
    
    private func setupLockWhisperLabel() {
        let label = UILabel()
        label.text = "LockWhisper V3"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        // Constrain the label to the top of the safe area with some padding.
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupBiometricSwitch() {
        let biometricLabel = UILabel()
        biometricLabel.text = "Enable Biometric Authentication"
        biometricLabel.font = UIFont.systemFont(ofSize: 16)
        biometricLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add both the label and the switch to the view.
        view.addSubview(biometricLabel)
        view.addSubview(biometricSwitch)
        
        // Add target to update the stored preference when the switch toggles.
        biometricSwitch.addTarget(self, action: #selector(biometricSwitchToggled(_:)), for: .valueChanged)
        
        // Place the switch and label below the LockWhisper label.
        NSLayoutConstraint.activate([
            biometricLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            biometricLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            biometricSwitch.centerYAnchor.constraint(equalTo: biometricLabel.centerYAnchor),
            biometricSwitch.leadingAnchor.constraint(equalTo: biometricLabel.trailingAnchor, constant: 16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func tipJarTapped() {
        let tipJarVC = TipJarViewController()
        navigationController?.pushViewController(tipJarVC, animated: true)
    }
    
    @objc private func biometricSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "biometricEnabled")
    }
}

// Extension to add migration features to SettingsViewController
extension SettingsViewController {
    
    // MARK: - Migration UI Setup
    
    func setupMigrationButtons() {
        // Create a label for the migration section
        let migrationLabel = UILabel()
        migrationLabel.text = "Device Migration"
        migrationLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        migrationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create export button
        let exportButton = StyledButton()
        exportButton.setTitle("Export App Data", for: .normal)
        exportButton.setStyle(.primary)
        exportButton.addTarget(self, action: #selector(exportDataTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Create import button
        let importButton = StyledButton()
        importButton.setTitle("Import App Data", for: .normal)
        importButton.setStyle(.secondary)
        importButton.addTarget(self, action: #selector(importDataTapped), for: .touchUpInside)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views to the main view
        view.addSubview(migrationLabel)
        view.addSubview(exportButton)
        view.addSubview(importButton)
        
        // Position the migration section below the biometric switch section
        let referenceBiometricLabel = view.subviews.first { subview in
            if let label = subview as? UILabel, label.text == "Enable Biometric Authentication" {
                return true
            }
            return false
        }
        
        NSLayoutConstraint.activate([
            migrationLabel.topAnchor.constraint(equalTo: referenceBiometricLabel?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 40),
            migrationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            migrationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            exportButton.topAnchor.constraint(equalTo: migrationLabel.bottomAnchor, constant: 16),
            exportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            exportButton.heightAnchor.constraint(equalToConstant: 44),
            
            importButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 12),
            importButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            importButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            importButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Export Data
    
    @objc func exportDataTapped() {
        let alert = UIAlertController(
            title: "Export App Data",
            message: "This will export all your app data for migration to another device. The data will be encrypted with a password. Continue?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.authenticateAndExport()
        })
        
        present(alert, animated: true)
    }
    
    private func authenticateAndExport() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to export app data") { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.promptForExportPassword()
                    } else if let error = error {
                        self?.showAlert(title: "Authentication Failed", message: error.localizedDescription)
                    }
                }
            }
        } else {
            // Fallback if biometric authentication is not available
            promptForExportPassword()
        }
    }
    
    private func promptForExportPassword() {
        let alert = UIAlertController(title: "Set Export Password", message: "Create a password to protect your exported data", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Confirm Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Export", style: .default) { [weak self, weak alert] _ in
            guard let alert = alert,
                  let passwordField = alert.textFields?[0],
                  let confirmField = alert.textFields?[1],
                  let password = passwordField.text,
                  let confirmPassword = confirmField.text,
                  !password.isEmpty else {
                self?.showAlert(title: "Error", message: "Password cannot be empty")
                return
            }
            
            if password != confirmPassword {
                self?.showAlert(title: "Error", message: "Passwords do not match")
                return
            }
            
            self?.performExport(withPassword: password)
        })
        
        present(alert, animated: true)
    }
    
    private func performExport(withPassword password: String) {
        // Show progress indicator
        let progressAlert = UIAlertController(title: "Exporting Data", message: "Please wait...", preferredStyle: .alert)
        present(progressAlert, animated: true)
        
        // Perform the export operation in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let exportURL = try self.createMigrationPackage(password: password)
                
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        // Show success message
                        self.showAlert(title: "Export Complete", message: "Your data has been successfully exported. Choose how you'd like to save the file.") { [weak self] in
                            guard let self = self else { return }
                            
                            // Ask user if they want to share with another app or save to Files
                            let actionSheet = UIAlertController(
                                title: "Export Options",
                                message: "Choose how to handle the exported file",
                                preferredStyle: .actionSheet
                            )
                            
                            actionSheet.addAction(UIAlertAction(title: "Save to Files", style: .default) { _ in
                                self.presentFileSaver(for: exportURL)
                            })
                            
                            actionSheet.addAction(UIAlertAction(title: "Share", style: .default) { _ in
                                self.presentShareSheet(for: exportURL)
                            })
                            
                            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                                // Clean up the file if the user cancels
                                try? FileManager.default.removeItem(at: exportURL)
                            })
                            
                            // On iPad, set the popover presentation controller
                            if let popoverController = actionSheet.popoverPresentationController {
                                popoverController.sourceView = self.view
                                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                                popoverController.permittedArrowDirections = []
                            }
                            
                            self.present(actionSheet, animated: true)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showAlert(title: "Export Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func createMigrationPackage(password: String) throws -> URL {
        // Create a temporary directory for our export files
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
        
        // 1. Export UserDefaults data
        try exportUserDefaults(to: temporaryDirectoryURL)
        
        // 2. Export CoreData for notes
        try exportCoreData(to: temporaryDirectoryURL)
        
        // 3. Export File Vault files
        try exportFileVault(to: temporaryDirectoryURL)
        
        // 4. Export Keychain items (PGP private keys, encryption keys)
        try exportKeychain(to: temporaryDirectoryURL)
        
        // 5. Create a manifest with metadata
        try createManifest(in: temporaryDirectoryURL)
        
        // Create the ZIP file
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("LockWhisper_Migration_\(Date().timeIntervalSince1970).zip")
        
        // Use your chosen zip library here - we're using a generic approach for flexibility
        if !createPasswordProtectedZip(from: temporaryDirectoryURL, to: zipURL, withPassword: password) {
            throw NSError(domain: "com.lockwhisper.migration", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to create zip archive"])
        }
        
        // Clean up the temporary directory
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        
        return zipURL
    }
    
    // Create a password-protected zip using ZipArchive
    private func createPasswordProtectedZip(from sourceDirectory: URL, to destinationURL: URL, withPassword password: String) -> Bool {
        // Use ZipArchive to create a password-protected zip
        return SSZipArchive.createZipFile(atPath: destinationURL.path,
                                         withContentsOfDirectory: sourceDirectory.path,
                                         keepParentDirectory: false,
                                         compressionLevel: 9,
                                         password: password,
                                         aes: true)
    }
    
    // Extract a password-protected zip using ZipArchive
    private func extractPasswordProtectedZip(from zipURL: URL, to directory: URL, withPassword password: String) -> Bool {
        // Use ZipArchive to extract a password-protected zip
        return SSZipArchive.unzipFile(atPath: zipURL.path,
                                     toDestination: directory.path,
                                     preserveAttributes: true,
                                     overwrite: true,
                                     password: password,
                                     error: nil,
                                     delegate: nil) // Add the delegate parameter
    }
    
    // Helper method to check if data is encrypted
    private func isEncryptedData(_ data: Data) -> Bool {
        // Check for version marker that identifies encrypted data
        return data.count > 0 && data[0] == 0x01  // Version 1
    }
    
    private func exportUserDefaults(to directory: URL) throws {
        // Get all UserDefaults keys we want to migrate
        let defaults = UserDefaults.standard
        
        // Create a directory structure for decrypted data
        var migratedData: [String: Any] = [:]
        
        // 1. Export biometric setting (not encrypted)
        migratedData["biometricEnabled"] = defaults.bool(forKey: "biometricEnabled")
        
        // 2. Export public PGP key (might be encrypted)
        if let publicKey = defaults.string(forKey: "publicPGPKey") {
            if PGPEncryptionManager.shared.isEncryptedBase64String(publicKey) {
                do {
                    let decryptedKey = try PGPEncryptionManager.shared.decryptBase64ToString(publicKey)
                    migratedData["publicPGPKey"] = decryptedKey
                } catch {
                    print("Error decrypting PGP key: \(error)")
                    migratedData["publicPGPKey"] = publicKey
                }
            } else {
                migratedData["publicPGPKey"] = publicKey
            }
        }
        
        // 3. Export contacts (decrypt them)
        if let contactsData = defaults.data(forKey: "savedContacts") {
            do {
                if isEncryptedData(contactsData) {
                    // Get encryption key and decrypt
                    let key = try getContactsEncryptionKey()
                    let decryptedData = try decryptData(contactsData, using: key)
                    
                    // Convert to array of dictionaries for JSON compatibility
                    let contacts = try JSONDecoder().decode([ContactContacts].self, from: decryptedData)
                    var contactDicts = [[String: Any]]()
                    
                    for contact in contacts {
                        var contactDict: [String: Any] = [
                            "name": contact.name
                        ]
                        
                        if let email1 = contact.email1 { contactDict["email1"] = email1 }
                        if let email2 = contact.email2 { contactDict["email2"] = email2 }
                        if let phone1 = contact.phone1 { contactDict["phone1"] = phone1 }
                        if let phone2 = contact.phone2 { contactDict["phone2"] = phone2 }
                        if let notes = contact.notes { contactDict["notes"] = notes }
                        
                        contactDicts.append(contactDict)
                    }
                    
                    migratedData["savedContacts"] = contactDicts
                } else {
                    // Handle legacy unencrypted data
                    let contacts = try JSONDecoder().decode([ContactContacts].self, from: contactsData)
                    var contactDicts = [[String: Any]]()
                    
                    for contact in contacts {
                        var contactDict: [String: Any] = [
                            "name": contact.name
                        ]
                        
                        if let email1 = contact.email1 { contactDict["email1"] = email1 }
                        if let email2 = contact.email2 { contactDict["email2"] = email2 }
                        if let phone1 = contact.phone1 { contactDict["phone1"] = phone1 }
                        if let phone2 = contact.phone2 { contactDict["phone2"] = phone2 }
                        if let notes = contact.notes { contactDict["notes"] = notes }
                        
                        contactDicts.append(contactDict)
                    }
                    
                    migratedData["savedContacts"] = contactDicts
                }
            } catch {
                print("Error decrypting contacts: \(error)")
                // Include encrypted data as fallback
                migratedData["savedContacts_encrypted"] = contactsData.base64EncodedString()
            }
        }
        
        // 4. Export PGP contacts (decrypt them)
        let pgpContacts = UserDefaults.standard.contacts
        
        // Convert PGP contacts to dictionaries
        var pgpContactDicts = [[String: Any]]()
        
        for contact in pgpContacts {
            var contactDict: [String: Any] = [
                "id": contact.id.uuidString,
                "name": contact.name,
                "publicKey": contact.publicKey,
                "messages": contact.messages,
                "messageDates": contact.messageDates
            ]
            
            if let notes = contact.notes { contactDict["notes"] = notes }
            
            pgpContactDicts.append(contactDict)
        }
        
        migratedData["contacts"] = pgpContactDicts
        
        // 5. Export passwords (decrypt them)
        if let passwordsData = defaults.data(forKey: "savedPasswords") {
            do {
                if PasswordEncryptionManager.shared.isEncryptedData(passwordsData) {
                    let decryptedData = try PasswordEncryptionManager.shared.decryptData(passwordsData)
                    let passwords = try JSONDecoder().decode([PasswordEntry].self, from: decryptedData)
                    
                    // Convert to array of dictionaries
                    var passwordDicts = [[String: String]]()
                    
                    for password in passwords {
                        passwordDicts.append([
                            "title": password.title,
                            "password": password.password
                        ])
                    }
                    
                    migratedData["savedPasswords"] = passwordDicts
                } else {
                    let passwords = try JSONDecoder().decode([PasswordEntry].self, from: passwordsData)
                    
                    // Convert to array of dictionaries
                    var passwordDicts = [[String: String]]()
                    
                    for password in passwords {
                        passwordDicts.append([
                            "title": password.title,
                            "password": password.password
                        ])
                    }
                    
                    migratedData["savedPasswords"] = passwordDicts
                }
            } catch {
                print("Error decrypting passwords: \(error)")
                // Include encrypted data as fallback
                migratedData["savedPasswords_encrypted"] = passwordsData.base64EncodedString()
            }
        }
        
        // Convert to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: migratedData, options: [.prettyPrinted])
        
        // Save to file
        let fileURL = directory.appendingPathComponent("user_defaults_decrypted.json")
        try jsonData.write(to: fileURL)
    }
    
    // Implementation of decryption that was in ContactsViewController
    private func decryptData(_ encryptedData: Data, using key: SymmetricKey) throws -> Data {
        // Ensure data has at least version byte
        guard encryptedData.count > 1 else {
            throw MigrationCryptoError.invalidData
        }

        // Check version
        let version = encryptedData[0]
        guard version == 0x01 else {
            throw MigrationCryptoError.unsupportedVersion(version)
        }

        // Extract encrypted data (everything after version byte)
        let sealedBoxData = encryptedData.subdata(in: 1..<encryptedData.count)

        // Create sealed box and decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // Implementation of ContactsKeychainManager.get from the original code
    private func getContactsKeychainData(account: String) throws -> Data? {
        let service = "com.lockwhisper.contacts"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw MigrationKeychainError.unhandledError(status: status)
        }

        return result as? Data
    }

    private func getContactsEncryptionKey() throws -> SymmetricKey {
        let keychainId = "com.lockwhisper.contacts.encryptionKey"

        // Get key data from the keychain
        guard let keyData = try getContactsKeychainData(account: keychainId)
        else {
            throw NSError(domain: "com.lockwhisper.migration", code: 4001,
                          userInfo: [NSLocalizedDescriptionKey: "Could not retrieve contacts encryption key"])
        }

        return SymmetricKey(data: keyData)
    }
    
    private func exportCoreData(to directory: URL) throws {
        // Instead of copying the encrypted database file directly,
        // export decrypted Note objects
        
        // 1. Read all Notes from CoreData
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let notes = try CoreDataManager.shared.context.fetch(fetchRequest)
        
        // 2. Create a decrypted representation (JSON array)
        var decryptedNotes: [[String: Any]] = []
        
        for note in notes {
            let storedText = note.text ?? ""
            let decryptedText: String
            
            // Decrypt if needed
            if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
                do {
                    decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                } catch {
                    print("Error decrypting note: \(error)")
                    decryptedText = storedText // Fallback to encrypted text
                }
            } else {
                decryptedText = storedText
            }
            
            decryptedNotes.append([
                "text": decryptedText,
                "createdAt": note.createdAt?.timeIntervalSince1970 ?? 0
            ])
        }
        
        // 3. Save decrypted representation to migration package
        let jsonData = try JSONSerialization.data(withJSONObject: decryptedNotes, options: [.prettyPrinted])
        try jsonData.write(to: directory.appendingPathComponent("notes_decrypted.json"))
    }
    
    private func exportFileVault(to directory: URL) throws {
        // Get the documents directory (where File Vault files are stored)
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "com.lockwhisper.migration", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        // Create destination directory
        let fileVaultDir = directory.appendingPathComponent("filevault", isDirectory: true)
        try FileManager.default.createDirectory(at: fileVaultDir, withIntermediateDirectories: true)
        
        // Get all files from the documents directory
        let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        
        // Create a metadata dictionary to store original filenames and decryption status
        var fileMetadata: [[String: Any]] = []
        
        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                // Read the file data
                let fileData = try Data(contentsOf: fileURL)
                
                // Check if file is encrypted
                if FileEncryptionManager.shared.isEncryptedData(fileData) {
                    // Decrypt the file
                    let decryptedData = try FileEncryptionManager.shared.decryptData(fileData)
                    try decryptedData.write(to: tempURL)
                    
                    // Use a unique filename for the decrypted file
                    let decryptedFilename = UUID().uuidString
                    let destinationURL = fileVaultDir.appendingPathComponent(decryptedFilename)
                    try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                    
                    // Store metadata
                    fileMetadata.append([
                        "originalName": filename,
                        "decryptedName": decryptedFilename,
                        "wasEncrypted": true
                    ])
                } else {
                    // File wasn't encrypted, just copy it
                    let destinationURL = fileVaultDir.appendingPathComponent(filename)
                    try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    
                    // Store metadata
                    fileMetadata.append([
                        "originalName": filename,
                        "decryptedName": filename,
                        "wasEncrypted": false
                    ])
                }
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
                
            } catch {
                print("Error processing file \(filename): \(error)")
                
                // If decryption fails, copy the original encrypted file as fallback
                let destinationURL = fileVaultDir.appendingPathComponent("encrypted_" + filename)
                try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                
                // Store metadata
                fileMetadata.append([
                    "originalName": filename,
                    "encryptedName": "encrypted_" + filename,
                    "wasEncrypted": true,
                    "decryptionFailed": true
                ])
            }
        }
        
        // Save metadata for reconstruction during import
        let metadataURL = fileVaultDir.appendingPathComponent("files_metadata.json")
        let metadataData = try JSONSerialization.data(withJSONObject: fileMetadata, options: [.prettyPrinted])
        try metadataData.write(to: metadataURL)
    }
    
    private func exportKeychain(to directory: URL) throws {
        // Export only the PGP private key - we're handling encryption/decryption differently now
        var keychainDict: [String: String] = [:]
        
        // PGP private key (may itself be encrypted)
        if let privateKeyEncrypted = try? KeychainHelper.shared.get(key: "privatePGPKey") {
            // Check if the private key is encrypted with our method
            if PGPEncryptionManager.shared.isEncryptedBase64String(privateKeyEncrypted) {
                do {
                    // Decrypt it for export
                    let decryptedKey = try PGPEncryptionManager.shared.decryptBase64ToString(privateKeyEncrypted)
                    keychainDict["privatePGPKey"] = decryptedKey
                } catch {
                    print("Error decrypting PGP private key: \(error)")
                    // Include the encrypted key as fallback
                    keychainDict["privatePGPKey_encrypted"] = privateKeyEncrypted
                }
            } else {
                // Just include the key as-is if it's not encrypted with our method
                keychainDict["privatePGPKey"] = privateKeyEncrypted
            }
        }
        
        // We don't need to export encryption keys anymore, since we're decrypting all data
        // before adding it to the migration package
        
        // Convert to JSON and save
        let jsonData = try JSONSerialization.data(withJSONObject: keychainDict, options: [.prettyPrinted])
        let fileURL = directory.appendingPathComponent("keychain_items.json")
        try jsonData.write(to: fileURL)
    }
    
    private func createManifest(in directory: URL) throws {
        // Create a manifest with metadata about the export
        let manifest: [String: Any] = [
            "version": "1.0",
            "appVersion": "LockWhisper V3",
            "exportDate": Date().timeIntervalSince1970,
            "deviceName": UIDevice.current.name,
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted])
        let fileURL = directory.appendingPathComponent("manifest.json")
        try jsonData.write(to: fileURL)
    }
    
    private func presentShareSheet(for fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Exclude some activity types
        activityViewController.excludedActivityTypes = [
            .assignToContact, .saveToCameraRoll, .postToTwitter, .postToFacebook,
            .postToWeibo, .print, .copyToPasteboard, .addToReadingList, .postToFlickr,
            .postToVimeo, .postToTencentWeibo
        ]
        
        // On iPad, set the popover presentation controller's source view
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func presentFileSaver(for fileURL: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
        documentPicker.shouldShowFileExtensions = true
        present(documentPicker, animated: true)
    }
    
    // MARK: - Import Data
    
    @objc func importDataTapped() {
        let alert = UIAlertController(
            title: "Import App Data",
            message: "This will import app data from a migration package. Your current data will be replaced. Continue?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.authenticateAndImport()
        })
        
        present(alert, animated: true)
    }
    
    private func authenticateAndImport() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to import app data") { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.presentFilePicker()
                    } else if let error = error {
                        self?.showAlert(title: "Authentication Failed", message: error.localizedDescription)
                    }
                }
            }
        } else {
            // Fallback if biometric authentication is not available
            presentFilePicker()
        }
    }
    
    private func presentFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    // MARK: - Import Processing
    
    private func processImportedFile(at url: URL) {
        // Prompt for the password to unlock the zip file
        let alert = UIAlertController(title: "Enter Password", message: "Enter the password for this migration package", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Import", style: .default) { [weak self, weak alert] _ in
            guard let password = alert?.textFields?.first?.text, !password.isEmpty else {
                self?.showAlert(title: "Error", message: "Password cannot be empty")
                return
            }
            
            self?.extractAndImport(zipURL: url, password: password)
        })
        
        present(alert, animated: true)
    }
    
    private func extractAndImport(zipURL: URL, password: String) {
        // Show progress indicator
        let progressAlert = UIAlertController(title: "Importing Data", message: "Please wait...", preferredStyle: .alert)
        present(progressAlert, animated: true)
        
        // Extract and process in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create a temporary directory for extraction
                let extractionDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true)
                
                // Extract the zip
                let success = self.extractPasswordProtectedZip(from: zipURL, to: extractionDir, withPassword: password)
                
                if !success {
                    throw NSError(domain: "com.lockwhisper.migration", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Failed to extract zip file. The password may be incorrect."])
                }
                
                // Process the extracted data
                try self.importFromDirectory(extractionDir)
                
                // Clean up
                try? FileManager.default.removeItem(at: extractionDir)
                try? FileManager.default.removeItem(at: zipURL)
                
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showAlert(title: "Import Complete", message: "Data has been successfully imported.") {
                            // Restart the app or notify the app needs restarting
                            self.showRestartPrompt()
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showAlert(title: "Import Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func importFromDirectory(_ directory: URL) throws {
        // Verify the manifest first
        try verifyManifest(in: directory)
        
        // Import in reverse order of export
        try importKeychain(from: directory)
        try importFileVault(from: directory)
        try importCoreData(from: directory)
        try importUserDefaults(from: directory)
    }
    
    private func verifyManifest(in directory: URL) throws {
        let manifestURL = directory.appendingPathComponent("manifest.json")
        
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2002, userInfo: [NSLocalizedDescriptionKey: "Invalid migration package: missing manifest"])
        }
        
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
        
        guard let version = manifest?["version"] as? String, version == "1.0",
              let appVersion = manifest?["appVersion"] as? String, appVersion.contains("LockWhisper") else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Invalid or incompatible migration package"])
        }
    }
    
    private func importUserDefaults(from directory: URL) throws {
        let userDefaultsURL = directory.appendingPathComponent("user_defaults_decrypted.json")
        
        guard FileManager.default.fileExists(atPath: userDefaultsURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2004, userInfo: [NSLocalizedDescriptionKey: "Missing user defaults data in migration package"])
        }
        
        let jsonData = try Data(contentsOf: userDefaultsURL)
        let importedData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        guard let importedData = importedData else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2005, userInfo: [NSLocalizedDescriptionKey: "Invalid user defaults format in migration package"])
        }
        
        let defaults = UserDefaults.standard
        
        // 1. Handle biometric setting (simple)
        if let biometricEnabled = importedData["biometricEnabled"] as? Bool {
            defaults.set(biometricEnabled, forKey: "biometricEnabled")
        }
        
        // 2. Handle public PGP key (needs encryption)
        if let publicKey = importedData["publicPGPKey"] as? String {
            do {
                // Re-encrypt the key before storing
                let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(publicKey)
                defaults.set(encryptedKey, forKey: "publicPGPKey")
            } catch {
                // Fall back to unencrypted if encryption fails
                defaults.set(publicKey, forKey: "publicPGPKey")
            }
        }
        
        // 3. Handle contacts (needs encryption)
        if let contacts = importedData["savedContacts"] as? [[String: Any]] {
            do {
                let contactsObjects = try JSONSerialization.data(withJSONObject: contacts)
                let contactsList = try JSONDecoder().decode([ContactContacts].self, from: contactsObjects)
                
                // Re-encrypt and save
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(contactsList)
                let key = try getOrCreateContactsEncryptionKey()
                let encryptedData = try encryptData(encodedData, using: key)
                defaults.set(encryptedData, forKey: "savedContacts")
            } catch {
                print("Error encrypting imported contacts: \(error)")
                
                // Look for fallback encrypted data
                if let encryptedData = importedData["savedContacts_encrypted"] as? String,
                   let data = Data(base64Encoded: encryptedData) {
                    defaults.set(data, forKey: "savedContacts")
                }
            }
        }
        
        // 4. Handle PGP contacts (use the extension setter which handles encryption)
        if let pgpContacts = importedData["contacts"] as? [[String: Any]] {
            do {
                let contactsData = try JSONSerialization.data(withJSONObject: pgpContacts)
                let contactsList = try JSONDecoder().decode([ContactPGP].self, from: contactsData)
                defaults.contacts = contactsList
            } catch {
                print("Error importing PGP contacts: \(error)")
            }
        }
        
        // 5. Handle passwords (needs encryption)
        if let passwords = importedData["savedPasswords"] as? [[String: Any]] {
            do {
                let passwordsData = try JSONSerialization.data(withJSONObject: passwords)
                let passwordList = try JSONDecoder().decode([PasswordEntry].self, from: passwordsData)
                
                // Re-encrypt and save
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(passwordList)
                let encryptedData = try PasswordEncryptionManager.shared.encryptData(encodedData)
                defaults.set(encryptedData, forKey: "savedPasswords")
            } catch {
                print("Error encrypting imported passwords: \(error)")
                
                // Look for fallback encrypted data
                if let encryptedData = importedData["savedPasswords_encrypted"] as? String,
                   let data = Data(base64Encoded: encryptedData) {
                    defaults.set(data, forKey: "savedPasswords")
                }
            }
        }
    }
    
    // Implementation of encryption for contacts re-encryption
    private func encryptData(_ data: Data, using key: SymmetricKey) throws -> Data {
        // Version marker (1 byte)
        var encryptedData = Data([0x01])

        // Generate a nonce for AES-GCM
        let nonce = try AES.GCM.Nonce()

        // Perform encryption
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        // Get combined data (nonce + ciphertext + tag)
        guard let combined = sealedBox.combined else {
            throw MigrationCryptoError.encryptionFailed
        }

        // Append encrypted data to version marker
        encryptedData.append(combined)

        return encryptedData
    }
    
    private func getOrCreateContactsEncryptionKey() throws -> SymmetricKey {
        let keychainId = "com.lockwhisper.contacts.encryptionKey"
        
        // Try to get existing key
        if let keyData = try? getContactsKeychainData(account: keychainId),
           !keyData.isEmpty {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        try saveContactsKeychainData(account: keychainId,
                                    data: newKey.withUnsafeBytes { Data($0) })
        return newKey
    }
    
    // Save data to keychain (implementation of ContactsKeychainManager.save)
    private func saveContactsKeychainData(account: String, data: Data) throws {
        let service = "com.lockwhisper.contacts"
        
        // Delete any existing item first
        try? deleteContactsKeychainData(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw MigrationKeychainError.unhandledError(status: status)
        }
    }
    
    // Delete data from keychain (implementation of ContactsKeychainManager.delete)
    private func deleteContactsKeychainData(account: String) throws {
        let service = "com.lockwhisper.contacts"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MigrationKeychainError.unhandledError(status: status)
        }
    }
    
    private func importCoreData(from directory: URL) throws {
        // Import decrypted notes instead of the database file
        let notesURL = directory.appendingPathComponent("notes_decrypted.json")
        
        guard FileManager.default.fileExists(atPath: notesURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2006, userInfo: [NSLocalizedDescriptionKey: "Missing notes data in migration package"])
        }
        
        // Load the decrypted notes
        let notesData = try Data(contentsOf: notesURL)
        let notesArray = try JSONSerialization.jsonObject(with: notesData) as? [[String: Any]]
        
        guard let notesArray = notesArray else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2007, userInfo: [NSLocalizedDescriptionKey: "Invalid notes format in migration package"])
        }
        
        // Clear existing notes from CoreData
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Note.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try context.execute(deleteRequest)
        
        // Create new notes with the imported data
        for noteDict in notesArray {
            guard let text = noteDict["text"] as? String else { continue }
            
            let note = Note(context: context)
            
            // Re-encrypt the note text before saving
            do {
                let encryptedText = try NoteEncryptionManager.shared.encryptStringToBase64(text)
                note.text = encryptedText
            } catch {
                // Fallback to unencrypted if encryption fails
                note.text = text
            }
            
            // Set created date
            if let timestamp = noteDict["createdAt"] as? TimeInterval {
                note.createdAt = Date(timeIntervalSince1970: timestamp)
            } else {
                note.createdAt = Date()
            }
        }
        
        // Save the context
        CoreDataManager.shared.saveContext()
    }
    
    private func importFileVault(from directory: URL) throws {
        // Get File Vault directory
        let fileVaultDir = directory.appendingPathComponent("filevault")
        
        guard FileManager.default.fileExists(atPath: fileVaultDir.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2009, userInfo: [NSLocalizedDescriptionKey: "Missing File Vault data in migration package"])
        }
        
        // Load file metadata
        let metadataURL = fileVaultDir.appendingPathComponent("files_metadata.json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2010, userInfo: [NSLocalizedDescriptionKey: "Missing file metadata in migration package"])
        }
        
        let metadataData = try Data(contentsOf: metadataURL)
        let filesMetadata = try JSONSerialization.jsonObject(with: metadataData) as? [[String: Any]]
        
        guard let filesMetadata = filesMetadata else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2011, userInfo: [NSLocalizedDescriptionKey: "Invalid file metadata format in migration package"])
        }
        
        // Get the documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2012, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        // Clear existing files
        let existingFiles = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        for fileURL in existingFiles {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        // Process each file according to metadata
        for fileInfo in filesMetadata {
            guard let originalName = fileInfo["originalName"] as? String else { continue }
            
            // Determine source file path
            let sourceFilename: String
            let wasEncrypted = fileInfo["wasEncrypted"] as? Bool ?? false
            let decryptionFailed = fileInfo["decryptionFailed"] as? Bool ?? false
            
            if decryptionFailed {
                // Use the encrypted backup file
                sourceFilename = fileInfo["encryptedName"] as? String ?? originalName
            } else {
                // Use the decrypted file
                sourceFilename = fileInfo["decryptedName"] as? String ?? originalName
            }
            
            let sourceURL = fileVaultDir.appendingPathComponent(sourceFilename)
            let destinationURL = documentsURL.appendingPathComponent(originalName)
            
            if wasEncrypted && !decryptionFailed {
                // File was successfully decrypted during export,
                // need to re-encrypt during import
                do {
                    let fileData = try Data(contentsOf: sourceURL)
                    let encryptedData = try FileEncryptionManager.shared.encryptData(fileData)
                    try encryptedData.write(to: destinationURL)
                } catch {
                    print("Error re-encrypting file \(originalName): \(error)")
                    
                    // Copy the file as-is as fallback
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                }
            } else {
                // Either the file wasn't encrypted originally or decryption failed,
                // just copy as-is
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            }
        }
    }
    
    private func importKeychain(from directory: URL) throws {
        // Get keychain items file
        let keychainURL = directory.appendingPathComponent("keychain_items.json")
        
        guard FileManager.default.fileExists(atPath: keychainURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2011, userInfo: [NSLocalizedDescriptionKey: "Missing keychain data in migration package"])
        }
        
        let jsonData = try Data(contentsOf: keychainURL)
        let keychainDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String]
        
        guard let keychainDict = keychainDict else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2012, userInfo: [NSLocalizedDescriptionKey: "Invalid keychain format in migration package"])
        }
        
        // Import PGP private key
        if let privateKey = keychainDict["privatePGPKey"] {
            // Re-encrypt the private key before saving
            do {
                let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(privateKey)
                try KeychainHelper.shared.save(key: "privatePGPKey", value: encryptedKey)
            } catch {
                // Fallback to saving unencrypted if encryption fails
                try KeychainHelper.shared.save(key: "privatePGPKey", value: privateKey)
            }
        } else if let encryptedKey = keychainDict["privatePGPKey_encrypted"] {
            // If we only have the encrypted version, save that
            try KeychainHelper.shared.save(key: "privatePGPKey", value: encryptedKey)
        }
        
        // We don't need to import encryption keys - new ones are automatically
        // generated by the various modules when needed
    }
    
    private func showRestartPrompt() {
        let alert = UIAlertController(
            title: "Restart Required",
            message: "The app needs to restart to complete the import process.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Restart Now", style: .default) { _ in
            // Simulate app restart - in a real app you might want to use UIApplication.shared.perform(...) or similar
            exit(0)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, url.startAccessingSecurityScopedResource() else {
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Make a local copy of the file before processing
        do {
            let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: temporaryURL.path) {
                try FileManager.default.removeItem(at: temporaryURL)
            }
            try FileManager.default.copyItem(at: url, to: temporaryURL)
            
            // Process the imported file
            processImportedFile(at: temporaryURL)
        } catch {
            showAlert(title: "Import Error", message: "Failed to copy the file: \(error.localizedDescription)")
        }
    }
}
