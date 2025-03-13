import CryptoKit
import UIKit

class ContactsViewController: UIViewController {

    // Key for local storage
    private let contactsKey = "savedContacts"
    // Array of ContactContacts objects
    private var contacts: [ContactContacts] = []

    // Create a table view to list contacts.
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contacts"
        view.backgroundColor = .systemBackground

        setupNavigationBar()
        loadContacts()
        setupTableView()
    }

    // MARK: - Setup Methods

    private func setupNavigationBar() {
        // Add plus button on right side.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addContactTapped)
        )
    }

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.dataSource = self
        tableView.delegate = self

        // Register a basic cell.
        tableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "contactCell")
    }

    // MARK: - Data Persistence with Encryption

    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: contactsKey) {
            do {
                let decoder = JSONDecoder()

                // Try to decrypt if the data is encrypted
                if isEncryptedData(data) {
                    let key = try getOrCreateEncryptionKey()
                    let decryptedData = try decryptData(data, using: key)
                    contacts = try decoder.decode(
                        [ContactContacts].self, from: decryptedData)
                } else {
                    // Handle legacy unencrypted data
                    if let savedContacts = try? decoder.decode(
                        [ContactContacts].self, from: data)
                    {
                        contacts = savedContacts
                    }
                }
            } catch {
                print("Failed to load contacts: \(error.localizedDescription)")
            }
        }
    }

    private func saveContacts() {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(contacts)

            // Encrypt the data
            let key = try getOrCreateEncryptionKey()
            let encryptedData = try encryptData(encodedData, using: key)

            // Save the encrypted data
            UserDefaults.standard.set(encryptedData, forKey: contactsKey)
        } catch {
            print("Error saving contacts: \(error.localizedDescription)")

            // Fallback to unencrypted storage if encryption fails
            if let encodedData = try? encoder.encode(contacts) {
                UserDefaults.standard.set(encodedData, forKey: contactsKey)
            }
        }
    }

    // MARK: - Crypto Helpers

    private func isEncryptedData(_ data: Data) -> Bool {
        // Check for version marker that identifies encrypted data
        return data.count > 0 && data[0] == 0x01  // Version 1
    }

    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to get existing key
        if let key = try getEncryptionKey() {
            return key
        }

        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        try saveEncryptionKey(newKey)
        return newKey
    }

    private func getEncryptionKey() throws -> SymmetricKey? {
        let keychainId = "com.lockwhisper.contacts.encryptionKey"

        // Get key data from the keychain
        guard let keyData = try ContactsKeychainManager.get(account: keychainId)
        else {
            return nil
        }

        return SymmetricKey(data: keyData)
    }

    private func saveEncryptionKey(_ key: SymmetricKey) throws {
        let keychainId = "com.lockwhisper.contacts.encryptionKey"

        // Convert key to Data and save to keychain
        let keyData = key.withUnsafeBytes { Data($0) }
        try ContactsKeychainManager.save(account: keychainId, data: keyData)
    }

    private func encryptData(_ data: Data, using key: SymmetricKey) throws
        -> Data
    {
        // Version marker (1 byte)
        var encryptedData = Data([0x01])

        // Generate a nonce for AES-GCM
        let nonce = try AES.GCM.Nonce()

        // Perform encryption
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        // Get combined data (nonce + ciphertext + tag)
        guard let combined = sealedBox.combined else {
            throw ContactsCryptoError.encryptionFailed
        }

        // Append encrypted data to version marker
        encryptedData.append(combined)

        return encryptedData
    }

    private func decryptData(_ encryptedData: Data, using key: SymmetricKey)
        throws -> Data
    {
        // Ensure data has at least version byte
        guard encryptedData.count > 1 else {
            throw ContactsCryptoError.invalidData
        }

        // Check version
        let version = encryptedData[0]
        guard version == 0x01 else {
            throw ContactsCryptoError.unsupportedVersion(version)
        }

        // Extract encrypted data (everything after version byte)
        let sealedBoxData = encryptedData.subdata(in: 1..<encryptedData.count)

        // Create sealed box and decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Actions

    @objc private func addContactTapped() {
        let addContactVC = AddContactViewController()
        addContactVC.delegate = self
        navigationController?.pushViewController(addContactVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ContactsViewController: UITableViewDataSource, UITableViewDelegate {

    // Number of contacts.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return contacts.count
    }

    // Configure each contact cell.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "contactCell", for: indexPath)
        let contact = contacts[indexPath.row]
        cell.textLabel?.text = contact.name
        return cell
    }

    // Swipe-to-delete functionality.
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive, title: "Delete"
        ) { [weak self] action, view, completionHandler in
            guard let self = self else { return }
            self.contacts.remove(at: indexPath.row)
            self.saveContacts()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = contacts[indexPath.row]
        let detailVC = ContactDetailViewController()
        detailVC.contact = contact
        detailVC.contactIndex = indexPath.row
        detailVC.delegate = self  // Make sure ContactsViewController conforms to ContactDetailDelegate
        navigationController?.pushViewController(detailVC, animated: true)
    }

}

// MARK: - Delegates

extension ContactsViewController: AddContactDelegate {
    func didAddContact(_ contact: ContactContacts) {
        contacts.append(contact)
        saveContacts()
        tableView.reloadData()
    }
}

extension ContactsViewController: ContactDetailDelegate {
    func didUpdateContact(_ updatedContact: ContactContacts, at index: Int) {
        // Update the contact in the array.
        contacts[index] = updatedContact
        // Save the updated contacts.
        saveContacts()
        // Reload the table view to reflect changes.
        tableView.reloadData()
    }
}

// MARK: - Error Types

enum ContactsCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

// MARK: - Keychain Manager

struct ContactsKeychainManager {
    private static let service = "com.lockwhisper.contacts"

    static func save(account: String, data: Data) throws {
        // Delete any existing item first
        try? delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw ContactsKeychainError.unhandledError(status: status)
        }
    }

    static func get(account: String) throws -> Data? {
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
            throw ContactsKeychainError.unhandledError(status: status)
        }

        return result as? Data
    }

    static func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ContactsKeychainError.unhandledError(status: status)
        }
    }
}

enum ContactsKeychainError: Error {
    case unhandledError(status: OSStatus)
}
