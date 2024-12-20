import UIKit

protocol MessageInputDelegate: AnyObject {
    func messageWasAdded()
}

protocol ContactInfoDelegate: AnyObject {
    func contactDidUpdate(_ contact: Contact)
}

extension ConversationViewController: MessageInputDelegate {
    func messageWasAdded() {
        if let contactsData = UserDefaults.standard.data(forKey: "contacts"),
           let contacts = try? JSONDecoder().decode([Contact].self, from: contactsData),
           let updatedContact = contacts.first(where: { $0.name == contact.name }) {
            // Update the local contact property with fresh data
            self.contact = updatedContact
        }
        tableView.reloadData()
    }
}

extension ConversationViewController: ContactInfoDelegate {
    func contactDidUpdate(_ contact: Contact) {
        self.contact = contact
        title = contact.name
    }
}

class ConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var contact: Contact
    private var tableView = UITableView()
    
    // Add the initializer
    init(contact: Contact) {
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
    private func setupNavigationItems() {
        let messageImage = UIImage(named: "addMessage")?.withRenderingMode(.alwaysTemplate)
        let infoImage = UIImage(named: "info")?.withRenderingMode(.alwaysTemplate)
        
        let messageButton = UIBarButtonItem(
            image: messageImage,
            style: .plain,
            target: self,
            action: #selector(messageButtonTapped)
        )
        messageButton.imageInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        let infoButton = UIBarButtonItem(
            image: infoImage,
            style: .plain,
            target: self,
            action: #selector(infoButtonTapped)
        )
        infoButton.imageInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        navigationItem.rightBarButtonItems = [infoButton, messageButton]
    }

    private func createBarButton(imageName: String, size: CGSize) -> UIBarButtonItem {
        let button = UIButton(frame: CGRect(origin: .zero, size: size))
        button.setImage(UIImage(named: imageName), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        
        if imageName == "addMessage" {
            button.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        }
        
        return UIBarButtonItem(customView: button)
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
