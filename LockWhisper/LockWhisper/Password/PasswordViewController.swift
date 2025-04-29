import UIKit
import CryptoKit

// MARK: - Model

struct PasswordEntry: Codable {
    var title: String
    var password: String
}

// MARK: - PasswordViewController

class PasswordViewController: UIViewController {
    
    // Data source using the model.
    var passwords: [PasswordEntry] = []
    private let passwordsKey = "savedPasswords"
    
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "PasswordCell")
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Passwords"
        setupNavigationBar()
        setupTableView()
        loadPasswords()
    }
    
    private func setupNavigationBar() {
        // Add button to allow the user to add a new password.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPasswordTapped)
        )
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func addPasswordTapped() {
        let detailVC = PasswordDetailViewController()
        detailVC.delegate = self
        // No pre-filled data means we are in "add" mode.
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Data Persistence with Encryption
    
    private func loadPasswords() {
        if let data = UserDefaults.standard.data(forKey: passwordsKey) {
            do {
                let decoder = JSONDecoder()
                
                // Try to decrypt if the data is encrypted
                if PasswordEncryptionManager.shared.isEncryptedData(data) {
                    let decryptedData = try PasswordEncryptionManager.shared.decryptData(data)
                    passwords = try decoder.decode([PasswordEntry].self, from: decryptedData)
                } else {
                    // Handle legacy unencrypted data
                    if let savedPasswords = try? decoder.decode([PasswordEntry].self, from: data) {
                        passwords = savedPasswords
                    }
                }
            } catch {
                print("Failed to load passwords: \(error.localizedDescription)")
            }
        }
    }
    
    private func savePasswords() {
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(passwords)
            // Encrypt the data
            let encryptedData = try PasswordEncryptionManager.shared.encryptData(encodedData)
            // Save the encrypted data
            UserDefaults.standard.set(encryptedData, forKey: passwordsKey)
        } catch {
            print("Error saving passwords: \(error.localizedDescription)")
            let allowFallback = UserDefaults.standard.bool(forKey: "allowUnencryptedFallback")
            if allowFallback {
                // Fallback to unencrypted storage if encryption fails
                if let encodedData = try? encoder.encode(passwords) {
                    UserDefaults.standard.set(encodedData, forKey: passwordsKey)
                }
            } else {
                // Alert the user and refuse to save
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Encryption Error", message: "Failed to encrypt your passwords. Your changes were NOT saved to prevent unencrypted storage.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension PasswordViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passwords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PasswordCell", for: indexPath)
        let entry = passwords[indexPath.row]
        cell.textLabel?.text = entry.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // When a password is tapped, show the detail view for editing.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = PasswordDetailViewController()
        detailVC.passwordEntry = passwords[indexPath.row]
        detailVC.entryIndex = indexPath.row // Pass along the index for editing.
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // Add swipe-to-delete functionality
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            passwords.remove(at: indexPath.row)
            savePasswords() // Save changes after deleting
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - PasswordDetailViewControllerDelegate

extension PasswordViewController: PasswordDetailViewControllerDelegate {
    func didSavePassword(entry: PasswordEntry, at index: Int?) {
        if let index = index {
            // Edit existing entry.
            passwords[index] = entry
            savePasswords()
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            // Add new entry.
            passwords.append(entry)
            savePasswords()
            let newIndexPath = IndexPath(row: passwords.count - 1, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
}
