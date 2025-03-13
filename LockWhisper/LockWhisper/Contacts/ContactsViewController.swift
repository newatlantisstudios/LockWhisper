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
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Register a basic cell.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "contactCell")
    }
    
    // MARK: - Data Persistence
    
    private func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: contactsKey) {
            let decoder = JSONDecoder()
            if let savedContacts = try? decoder.decode([ContactContacts].self, from: data) {
                contacts = savedContacts
            }
        }
    }
    
    private func saveContacts() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(contacts) {
            UserDefaults.standard.set(encodedData, forKey: contactsKey)
        }
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    // Configure each contact cell.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath)
        let contact = contacts[indexPath.row]
        cell.textLabel?.text = contact.name
        return cell
    }
    
    // Swipe-to-delete functionality.
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completionHandler in
            guard let self = self else { return }
            self.contacts.remove(at: indexPath.row)
            self.saveContacts()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

