import UIKit
import CoreData

protocol NewNoteDelegate: AnyObject {
    func didAddNewNote(_ noteText: String)
}

class NotepadViewController: UIViewController {
    
    // Array to store fetched Note objects.
    var notes: [Note] = []
    
    // Table view to display notes.
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.tableFooterView = UIView() // Hide empty cells.
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notepad"
        view.backgroundColor = .systemBackground
        setupTableView()
        setupNavigationBar()
        fetchNotes()
        
        // Index existing notes for search
        updateSearchIndex()
        
        // Register for favorites changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesDidChange),
            name: .favoritesDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func favoritesDidChange() {
        // Refresh the table to update favorite indicators
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BiometricAuthManager.shared.authenticateIfNeeded(from: self)
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
            action: #selector(addNoteTapped)
        )
    }
    
    @objc private func addNoteTapped() {
        let newNoteVC = NewNoteViewController()
        newNoteVC.delegate = self
        navigationController?.pushViewController(newNoteVC, animated: true)
    }
    
    // Fetch notes from Core Data.
    func fetchNotes() {
        let fetchRequest: NSFetchRequest<Note> = NSFetchRequest(entityName: "Note")
        do {
            notes = try CoreDataManager.shared.context.fetch(fetchRequest)
            tableView.reloadData()
        } catch {
            print("Failed to fetch notes: \(error)")
        }
    }
    
    // Delete note from Core Data.
    func deleteNote(at indexPath: IndexPath) {
        let noteToDelete = notes[indexPath.row]
        CoreDataManager.shared.context.delete(noteToDelete)
        CoreDataManager.shared.saveContext()
        notes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

extension NotepadViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Number of rows equals the count of notes.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    // Configure each cell with the note's text.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "NoteCell")
        
        let note = notes[indexPath.row]
        let storedText = note.text ?? ""
        
        // Try to decrypt the text if it's encrypted
        if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
            do {
                let decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                cell.textLabel?.text = decryptedText
            } catch {
                // Fallback to the stored text if decryption fails
                cell.textLabel?.text = storedText
                print("Failed to decrypt note: \(error)")
            }
        } else {
            // Use the plain text for unencrypted notes
            cell.textLabel?.text = storedText
        }
        
        // Show favorite status
        if FavoritesManager.shared.isFavorite(id: note.objectID.uriRepresentation().absoluteString, moduleType: ModuleType.notes) {
            cell.imageView?.image = UIImage(systemName: "star.fill")
            cell.imageView?.tintColor = .systemYellow
        } else {
            cell.imageView?.image = nil
        }
        
        return cell
    }
    
    // Enable swipe-to-delete.
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let noteToDelete = notes[indexPath.row]
            
            // Remove from favorites if it was favorited
            let noteId = noteToDelete.objectID.uriRepresentation().absoluteString
            if FavoritesManager.shared.isFavorite(id: noteId, moduleType: ModuleType.notes) {
                FavoritesManager.shared.removeFavorite(id: noteId, moduleType: ModuleType.notes)
            }
            
            deleteNote(at: indexPath)
        }
    }
    
    // Add swipe actions for favorite toggle
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let note = notes[indexPath.row]
        let noteId = note.objectID.uriRepresentation().absoluteString
        
        // Create favorite action
        let isFavorite = FavoritesManager.shared.isFavorite(id: noteId, moduleType: ModuleType.notes)
        
        let actionTitle = isFavorite ? "Unfavorite" : "Favorite"
        let actionIcon = isFavorite ? "star.slash" : "star"
        
        let favoriteAction = UIContextualAction(style: .normal, title: actionTitle) { (_, _, completion) in
            // Toggle favorite status
            if isFavorite {
                FavoritesManager.shared.removeFavorite(id: noteId, moduleType: ModuleType.notes)
            } else {
                FavoritesManager.shared.addFavorite(item: note)
            }
            
            // Update cell
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            
            completion(true)
        }
        
        favoriteAction.image = UIImage(systemName: actionIcon)
        favoriteAction.backgroundColor = .systemYellow
        
        // Add delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completion) in
            self.deleteNote(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, favoriteAction])
    }
    
    // When a cell is tapped, open the note in detail.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let note = notes[indexPath.row]
        let detailVC = NoteDetailViewController(note: note, index: indexPath.row)
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension NotepadViewController {
    // Override the existing cellForRowAt method to add decryption
    func tableViewCell(for note: Note) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "NoteCell")
        let storedText = note.text ?? ""
        
        // Try to decrypt the text if it's encrypted
        if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
            do {
                let decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                cell.textLabel?.text = decryptedText
            } catch {
                // Fallback to the stored text if decryption fails
                cell.textLabel?.text = storedText
                print("Failed to decrypt note: \(error)")
            }
        } else {
            // Use the plain text for unencrypted notes
            cell.textLabel?.text = storedText
        }
        
        return cell
    }
}

extension NotepadViewController: NewNoteDelegate {
    func didAddNewNote(_ noteText: String) {
        let context = CoreDataManager.shared.context
        let note = Note(context: context)
        do {
            // Encrypt the text before saving
            let encryptedBase64 = try NoteEncryptionManager.shared.encryptStringToBase64(noteText)
            note.text = encryptedBase64
            note.createdAt = Date()
            CoreDataManager.shared.saveContext()
            notes.append(note)
            let newIndexPath = IndexPath(row: notes.count - 1, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            
            // Index the new note for search
            indexNote(note)
        } catch {
            print("Failed to encrypt note: \(error.localizedDescription)")
            let allowFallback = UserDefaults.standard.bool(forKey: "allowUnencryptedFallback")
            if allowFallback {
                // Fallback to saving unencrypted if encryption fails
                note.text = noteText
                note.createdAt = Date()
                CoreDataManager.shared.saveContext()
                notes.append(note)
                let newIndexPath = IndexPath(row: notes.count - 1, section: 0)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
                // Index the new note for search
                indexNote(note)
            } else {
                // Alert the user and refuse to save
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Encryption Error", message: "Failed to encrypt your note. Your note was NOT saved to prevent unencrypted storage.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

protocol NoteDetailDelegate: AnyObject {
    func didUpdateNote(_ noteText: String, at index: Int)
}

extension NotepadViewController: NoteDetailDelegate {
    func didUpdateNote(_ noteText: String, at index: Int) {
        let note = notes[index]
        do {
            // Encrypt the text before saving
            let encryptedBase64 = try NoteEncryptionManager.shared.encryptStringToBase64(noteText)
            note.text = encryptedBase64
            CoreDataManager.shared.saveContext()
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } catch {
            print("Failed to encrypt updated note: \(error.localizedDescription)")
            let allowFallback = UserDefaults.standard.bool(forKey: "allowUnencryptedFallback")
            if allowFallback {
                // Fallback to saving unencrypted if encryption fails
                note.text = noteText
                CoreDataManager.shared.saveContext()
                let indexPath = IndexPath(row: index, section: 0)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                // Alert the user and refuse to save
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Encryption Error", message: "Failed to encrypt your note. Your changes were NOT saved to prevent unencrypted storage.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
