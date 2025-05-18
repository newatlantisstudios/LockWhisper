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
    private var usingFakeMode: Bool = false
    
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
        
        // Initialize decoy passwords if needed
        if FakePasswordManager.shared.isFakePasswordEnabled {
            DecoyPasswordManager.shared.initializeDecoyPasswordsIfNeeded()
        }
        
        loadPasswords()
        updateUIForCurrentMode()
    }
    
    private func updateUIForCurrentMode() {
        if FakePasswordManager.shared.isInFakeMode {
            // Subtle orange tint for decoy mode
            tableView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.05)
            navigationController?.navigationBar.tintColor = .systemOrange
        } else {
            // Normal appearance for secure mode
            tableView.backgroundColor = .systemBackground
            navigationController?.navigationBar.tintColor = nil
        }
    }
    
    private func setupNavigationBar() {
        // Add button to allow the user to add a new password.
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPasswordTapped)
        )
        
        // Add refresh button for decoy mode
        if FakePasswordManager.shared.isInFakeMode && FakePasswordManager.shared.isFakePasswordEnabled {
            let refreshButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(refreshDecoyPasswordsTapped)
            )
            navigationItem.rightBarButtonItems = [addButton, refreshButton]
        } else {
            navigationItem.rightBarButtonItem = addButton
        }
        
        // Add mode indicator and toggle button if fake password is enabled
        if FakePasswordManager.shared.isFakePasswordEnabled {
            // Create a mode indicator label
            let modeLabel = UILabel()
            modeLabel.text = FakePasswordManager.shared.isInFakeMode ? "🔓 Decoy Mode" : "🔒 Secure Mode"
            modeLabel.font = .systemFont(ofSize: 14, weight: .medium)
            modeLabel.textColor = FakePasswordManager.shared.isInFakeMode ? .systemOrange : .systemGreen
            modeLabel.sizeToFit()
            
            // Create toggle button
            let toggleButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.left.arrow.right"),
                style: .plain,
                target: self,
                action: #selector(toggleModeTapped)
            )
            
            // Combine label and toggle button
            let labelBarItem = UIBarButtonItem(customView: modeLabel)
            navigationItem.leftBarButtonItems = [labelBarItem, toggleButton]
        }
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
    
    @objc private func toggleModeTapped() {
        // Show confirmation alert before switching modes
        let currentMode = FakePasswordManager.shared.isInFakeMode ? "Decoy" : "Secure"
        let targetMode = FakePasswordManager.shared.isInFakeMode ? "Secure" : "Decoy"
        
        let alert = UIAlertController(
            title: "Switch to \(targetMode) Mode?",
            message: "You are currently in \(currentMode) Mode. Switch to \(targetMode) Mode?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Switch", style: .default) { [weak self] _ in
            self?.performModeSwitch()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func refreshDecoyPasswordsTapped() {
        let alert = UIAlertController(
            title: "Refresh Decoy Passwords?",
            message: "This will replace all current decoy passwords with new random data. Existing decoy passwords will be lost.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Refresh", style: .destructive) { [weak self] _ in
            self?.refreshDecoyPasswords()
        })
        
        present(alert, animated: true)
    }
    
    private func refreshDecoyPasswords() {
        // Generate new decoy passwords
        DecoyPasswordManager.shared.refreshDecoyPasswords()
        
        // Animate the refresh
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve) { [weak self] in
            self?.loadPasswords()
            self?.tableView.reloadData()
        }
        
        // Show feedback
        let banner = UIView()
        banner.backgroundColor = .systemOrange
        banner.layer.cornerRadius = 25
        banner.layer.masksToBounds = true
        banner.alpha = 0
        
        let label = UILabel()
        label.text = "✓ Decoy passwords refreshed"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        
        banner.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            banner.widthAnchor.constraint(equalToConstant: 250),
            banner.heightAnchor.constraint(equalToConstant: 50),
            
            label.centerXAnchor.constraint(equalTo: banner.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: banner.centerYAnchor)
        ])
        
        // Animate banner
        UIView.animate(withDuration: 0.3, animations: {
            banner.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                banner.alpha = 0
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }
    
    private func performModeSwitch() {
        // Toggle the mode in FakePasswordManager
        if FakePasswordManager.shared.isInFakeMode {
            FakePasswordManager.shared.currentMode = .real
        } else {
            FakePasswordManager.shared.currentMode = .fake
        }
        
        // Animate the transition
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve) { [weak self] in
            self?.loadPasswords()
            self?.tableView.reloadData()
            self?.updateUIForCurrentMode()
        } completion: { [weak self] _ in
            // Update navigation bar after switch
            self?.setupNavigationBar()
        }
        
        // Show feedback
        let modeName = FakePasswordManager.shared.isInFakeMode ? "Decoy Mode" : "Secure Mode"
        let banner = UIView()
        banner.backgroundColor = FakePasswordManager.shared.isInFakeMode ? .systemOrange : .systemGreen
        banner.layer.cornerRadius = 25
        banner.layer.masksToBounds = true
        banner.alpha = 0
        
        let label = UILabel()
        label.text = "✓ Switched to \(modeName)"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        
        banner.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            banner.widthAnchor.constraint(equalToConstant: 200),
            banner.heightAnchor.constraint(equalToConstant: 50),
            
            label.centerXAnchor.constraint(equalTo: banner.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: banner.centerYAnchor)
        ])
        
        // Animate banner appearance and disappearance
        UIView.animate(withDuration: 0.3, animations: {
            banner.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                banner.alpha = 0
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Data Persistence with Encryption
    
    private func loadPasswords() {
        usingFakeMode = FakePasswordManager.shared.isInFakeMode
        let actualKey = FakePasswordManager.shared.getUserDefaultsKey(for: passwordsKey)
        
        if let data = UserDefaults.standard.data(forKey: actualKey) {
            do {
                let decoder = JSONDecoder()
                
                // Use appropriate encryption manager based on mode
                let encryptionManager = getEncryptionManager()
                
                // Try to decrypt if the data is encrypted
                if encryptionManager.isEncryptedData(data) {
                    let decryptedData = try encryptionManager.decryptData(data)
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
            // Use appropriate encryption manager based on mode
            let encryptionManager = getEncryptionManager()
            let encryptedData = try encryptionManager.encryptData(encodedData)
            // Save to appropriate UserDefaults key
            let actualKey = FakePasswordManager.shared.getUserDefaultsKey(for: passwordsKey)
            UserDefaults.standard.set(encryptedData, forKey: actualKey)
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
    
    // MARK: - Helper Methods
    
    private func getEncryptionManager() -> any SymmetricEncryptionManagerProtocol {
        if FakePasswordManager.shared.isInFakeMode {
            // Create encryption manager with fake keychain
            let fakeKeychainManager = FakePasswordKeychainManager()
            let fakeEncryptionManager = SymmetricEncryptionManager(
                keychainManager: fakeKeychainManager,
                keychainId: FakePasswordManager.shared.getEncryptionKey(for: Constants.passwordsEncryptionKey)
            )
            return fakeEncryptionManager
        } else {
            return PasswordEncryptionManager.shared
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
    
    // Customize swipe actions appearance based on mode
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            self?.passwords.remove(at: indexPath.row)
            self?.savePasswords()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        
        // Use different color for decoy mode
        if FakePasswordManager.shared.isInFakeMode {
            deleteAction.backgroundColor = .systemOrange
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
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
