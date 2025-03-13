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
            UITableViewCell(style: .default, reuseIdentifier: "NoteCell")
        let note = notes[indexPath.row]
        cell.textLabel?.text = note.text
        return cell
    }
    
    // Enable swipe-to-delete.
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteNote(at: indexPath)
        }
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

extension NotepadViewController: NewNoteDelegate {
    func didAddNewNote(_ noteText: String) {
        let context = CoreDataManager.shared.context
        let note = Note(context: context)
        note.text = noteText
        note.createdAt = Date()
        CoreDataManager.shared.saveContext()
        notes.append(note)
        tableView.reloadData()
    }
}

protocol NoteDetailDelegate: AnyObject {
    func didUpdateNote(_ noteText: String, at index: Int)
}

extension NotepadViewController: NoteDetailDelegate {
    func didUpdateNote(_ noteText: String, at index: Int) {
        let note = notes[index]
        note.text = noteText
        CoreDataManager.shared.saveContext()
        tableView.reloadData()
    }
}
