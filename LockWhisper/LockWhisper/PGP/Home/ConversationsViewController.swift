import UIKit

class ConversationsViewController: UIViewController {
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Conversations"
        setupUI()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        let gearButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(settingsButtonTapped))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        // The first item in rightBarButtonItems is placed at the far right.
        navigationItem.rightBarButtonItems = [gearButton, addButton]
    }
    
    @objc private func settingsButtonTapped() {
        let settingsViewController = PGPSettingsViewController()
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    @objc private func addButtonTapped() {
        let addViewController = AddConversationViewController()
        addViewController.delegate = self
        let navController = UINavigationController(rootViewController: addViewController)
        present(navController, animated: true)
    }
}

extension ConversationsViewController: AddConversationDelegate {
    func didAddNewConversation() {
        tableView.reloadData()
    }
}

extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserDefaults.standard.contacts.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var contacts = UserDefaults.standard.contacts
            contacts.remove(at: indexPath.row)
            UserDefaults.standard.contacts = contacts
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        let contact = UserDefaults.standard.contacts[indexPath.row]
        cell.configure(with: contact)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = UserDefaults.standard.contacts[indexPath.row]
        let conversationVC = ConversationViewController(contact: contact)
        navigationController?.pushViewController(conversationVC, animated: true)
    }
}
