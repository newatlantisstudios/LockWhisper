import UIKit

// MARK: - Model

struct PasswordEntry {
    var title: String
    var password: String
}

// MARK: - PasswordViewController

class PasswordViewController: UIViewController {
    
    // Data source using the model.
    var passwords: [PasswordEntry] = [
        PasswordEntry(title: "Email", password: "emailPass123"),
        PasswordEntry(title: "Bank", password: "bankPass456")
    ]
    
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
}

// MARK: - PasswordDetailViewControllerDelegate

extension PasswordViewController: PasswordDetailViewControllerDelegate {
    func didSavePassword(entry: PasswordEntry, at index: Int?) {
        if let index = index {
            // Edit existing entry.
            passwords[index] = entry
        } else {
            // Add new entry.
            passwords.append(entry)
        }
        tableView.reloadData()
    }
}
