import UIKit

protocol MessageInputDelegate: AnyObject {
    func messageWasAdded()
}

protocol ContactInfoDelegate: AnyObject {
    func contactDidUpdate(_ contact: ContactPGP)
}

extension ConversationViewController: MessageInputDelegate {
    func messageWasAdded() {
        // Get contacts directly from a method instead of property to fix ambiguity
        let pgpManager = PGPEncryptionManager.shared
        let contacts = pgpManager.getContacts()
        
        // Find and update the contact
        if let updatedContact = contacts.first(where: { $0.name == contact.name }) {
            // Update the local contact property with fresh data
            self.contact = updatedContact
        }
        tableView.reloadData()
    }
}

extension ConversationViewController: ContactInfoDelegate {
    func contactDidUpdate(_ contact: ContactPGP) {
        self.contact = contact
        title = contact.name
    }
}

class ConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var contact: ContactPGP
    private var tableView = UITableView()
    
    // Add the initializer
    init(contact: ContactPGP) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = contact.name
        
        view.backgroundColor = .white
        setupTableView()
        setupNavigationItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh the local contact copy from persistent storage.
        if let updatedContact = UserDefaults.standard.contacts.first(where: { $0.name == contact.name }) {
            self.contact = updatedContact
            // Update any UI elements if necessary.
            // For example, if you display notes somewhere, reload that part of the UI.
        }
    }
    
    // MARK: - Setup TableView
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConversationMessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.rowHeight = 55
        tableView.allowsSelection = false
        
        view.addSubview(tableView)
        
        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Setup Buttons
    
    // Helper method to create a bar button of consistent size.
    private func createBarButton(imageName: String, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        if let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(image, for: .normal)
        }
        
        // Set a fixed frame or use constraints for a consistent size.
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .label // or whatever tint you prefer
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // Wrap it in a UIBarButtonItem
        let barButtonItem = UIBarButtonItem(customView: button)
        
        // Optionally use Auto Layout constraints for an even more robust approach:
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return barButtonItem
    }
    
    // MARK: - Setup Navigation Items
    private func setupNavigationItems() {
        // Create each bar button with the same sizing approach.
        let messageButton = createBarButton(imageName: "addMessage",
                                            action: #selector(messageButtonTapped))
        let infoButton = createBarButton(imageName: "info",
                                         action: #selector(infoButtonTapped))
        let notesButton = createBarButton(imageName: "notes",
                                          action: #selector(notesButtonTapped))
        
        navigationItem.rightBarButtonItems = [infoButton, messageButton, notesButton]
    }

    @objc private func notesButtonTapped() {
        let notesVC = NotesViewController(contact: contact)
        navigationController?.pushViewController(notesVC, animated: true)
    }
    
    @objc private func infoButtonTapped() {
        let infoVC = ContactInfoViewController(contact: contact)
        infoVC.delegate = self
        navigationController?.pushViewController(infoVC, animated: true)
    }
    
    @objc private func messageButtonTapped() {
        let inputVC = MessageInputViewController()
        inputVC.contact = contact
        inputVC.delegate = self
        present(inputVC, animated: true)
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contact.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //print("Loading message at index:", indexPath.row)
        //print("Total messages:", contact.messages.count)
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! ConversationMessageCell
        
        let message = contact.messages[indexPath.row]
        let date = contact.messageDates[indexPath.row]
        
        cell.configure(text: message, date: date)
        
        return cell
    }
    
}
