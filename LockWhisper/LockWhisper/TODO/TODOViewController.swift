import UIKit
import CoreData

class TODOViewController: UIViewController {
    
    // Array to store fetched TODOItems objects
    var todoItems: [TODOItem] = []
    
    // Table view to display TODOs
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.tableFooterView = UIView() // Hide empty cells
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TODO List"
        view.backgroundColor = .systemBackground
        setupTableView()
        setupNavigationBar()
        fetchTODOItems()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTODOTapped)
        )
    }
    
    @objc private func addTODOTapped() {
        let newTODO = NewTODOViewController()
        newTODO.delegate = self
        newTODO.modalPresentationStyle = .formSheet
        present(newTODO, animated: true)
    }
    
    private func addNewTODO(_ title: String) {
        let context = CoreDataManager.shared.context
        do {
            let encryptedTitle = try TODOEncryptionManager.shared.encryptStringToBase64(title)
            let todoItem = TODOItem(context: context)
            todoItem.title = encryptedTitle
            todoItem.completed = false
            todoItem.createdAt = Date()
            CoreDataManager.shared.saveContext()
            todoItems.append(todoItem)
            let newIndexPath = IndexPath(row: todoItems.count - 1, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        } catch {
            print("Failed to encrypt TODO title: \(error.localizedDescription)")
            let todoItem = TODOItem(context: context)
            todoItem.title = title
            todoItem.completed = false
            todoItem.createdAt = Date()
            CoreDataManager.shared.saveContext()
            todoItems.append(todoItem)
            let newIndexPath = IndexPath(row: todoItems.count - 1, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
    
    // Fetch TODO items from Core Data
    func fetchTODOItems() {
        let fetchRequest: NSFetchRequest<TODOItem> = NSFetchRequest(entityName: Constants.todoItemEntity)
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            todoItems = try CoreDataManager.shared.context.fetch(fetchRequest)
            tableView.reloadData()
        } catch {
            print("Failed to fetch TODO items: \(error)")
        }
    }
    
    // Delete TODO item from Core Data
    func deleteTODOItem(at indexPath: IndexPath) {
        let todoToDelete = todoItems[indexPath.row]
        CoreDataManager.shared.context.delete(todoToDelete)
        CoreDataManager.shared.saveContext()
        todoItems.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    // Toggle completion status of a TODO item
    func toggleTODOCompletion(at indexPath: IndexPath) {
        let todoItem = todoItems[indexPath.row]
        todoItem.completed.toggle()
        CoreDataManager.shared.saveContext()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension TODOViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Number of rows equals the count of TODO items
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count
    }
    
    // Configure each cell with the TODO item's title and completion status
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TODOCell") ??
            UITableViewCell(style: .default, reuseIdentifier: "TODOCell")
        
        let todoItem = todoItems[indexPath.row]
        let storedTitle = todoItem.title ?? ""
        let completed = todoItem.completed
        
        // Try to decrypt the title if it's encrypted
        if TODOEncryptionManager.shared.isEncryptedBase64String(storedTitle) {
            do {
                let decryptedTitle = try TODOEncryptionManager.shared.decryptBase64ToString(storedTitle)
                cell.textLabel?.text = decryptedTitle
            } catch {
                // Fallback to the stored title if decryption fails
                cell.textLabel?.text = storedTitle
                print("Failed to decrypt TODO title: \(error)")
            }
        } else {
            // Use the plain text for unencrypted titles
            cell.textLabel?.text = storedTitle
        }
        
        // Set checkmark for completed items
        cell.accessoryType = completed ? .checkmark : .none
        
        return cell
    }
    
    // Enable swipe-to-delete
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteTODOItem(at: indexPath)
        }
    }
    
    // When a cell is tapped, toggle completion status
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        toggleTODOCompletion(at: indexPath)
    }
}

// Add delegate conformance
extension TODOViewController: NewTODODelegate {
    func didAddNewTODO(_ title: String) {
        dismiss(animated: true) {
            self.addNewTODO(title)
        }
    }
    func didCancelNewTODO() {
        dismiss(animated: true)
    }
}
