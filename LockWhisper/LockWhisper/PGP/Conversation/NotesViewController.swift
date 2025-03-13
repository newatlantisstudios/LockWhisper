import UIKit

class NotesViewController: UIViewController {
    private var contact: ContactPGP
    private let textView = UITextView()
    
    // Initialize with the conversation's contact so the notes remain unique.
    init(contact: ContactPGP) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes for \(contact.name)"
        
        setupUI()
        // Load existing notes, if any.
        textView.text = contact.notes ?? ""
    }
    
    private func setupUI() {
        // Use dynamic system colors for backgrounds and labels.
        view.backgroundColor = .systemBackground
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // This ensures any unsaved changes are committed and stored.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        
        contact.notes = textView.text
        
        var contacts = UserDefaults.standard.contacts
        if let index = contacts.firstIndex(where: { $0.name == contact.name }) {
            contacts[index] = contact
            UserDefaults.standard.contacts = contacts
        }
    }
    
    // If the user changes appearance (e.g., from light to dark) while this view is active:
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Check if the appearance changed (light <-> dark).
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    // Update dynamic colors if needed.
    private func updateColors() {
        view.backgroundColor = .systemBackground
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
    }
}
