import UIKit
import UniformTypeIdentifiers

struct ContactPGP: Codable {
    var id: UUID
    var name: String
    var publicKey: String
    var messages: [String]
    var messageDates: [String]
    var notes: String?

    // Updated initializer with an auto-generated id by default.
    init(id: UUID = UUID(), name: String, publicKey: String, messages: [String] = [], messageDates: [String] = [], notes: String? = nil) {
        self.id = id
        self.name = name
        self.publicKey = publicKey
        self.messages = messages
        self.messageDates = messageDates
        self.notes = notes
    }
    
    // Custom decoding to handle old conversations that might be missing an id.
    private enum CodingKeys: String, CodingKey {
        case id, name, publicKey, messages, messageDates, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // If there's no id present, generate one.
        if let id = try? container.decode(UUID.self, forKey: .id) {
            self.id = id
        } else {
            self.id = UUID()
        }
        self.name = try container.decode(String.self, forKey: .name)
        self.publicKey = try container.decode(String.self, forKey: .publicKey)
        self.messages = try container.decode([String].self, forKey: .messages)
        self.messageDates = try container.decode([String].self, forKey: .messageDates)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}


protocol AddConversationDelegate: AnyObject {
    func didAddNewConversation()
}

class AddConversationViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Contact with PGP Key"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let publicKeyTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let importFileButton: StyledButton = {
        let button = StyledButton()
        button.setTitle("Import Public Key from File app", for: .normal)
        button.setStyle(.secondary)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let importToConversationsButton: StyledButton = {
        let button = StyledButton()
        button.setTitle("Import to conversations", for: .normal)
        button.setStyle(.primary)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    weak var delegate: AddConversationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
            updateInterfaceColors()
        
        view.addSubview(titleLabel)
        view.addSubview(publicKeyTextView)
        view.addSubview(importFileButton)
        view.addSubview(importToConversationsButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            publicKeyTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            publicKeyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            publicKeyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            publicKeyTextView.heightAnchor.constraint(equalToConstant: 200),
            
            importFileButton.topAnchor.constraint(equalTo: publicKeyTextView.bottomAnchor, constant: 20),
            importFileButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            importToConversationsButton.topAnchor.constraint(equalTo: importFileButton.bottomAnchor, constant: 20),
            importToConversationsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupActions() {
        importFileButton.addTarget(self, action: #selector(importButtonTapped), for: .touchUpInside)
        importToConversationsButton.addTarget(self, action: #selector(importToConversationsTapped), for: .touchUpInside)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateInterfaceColors()
        }
    }
    
    private func updateInterfaceColors() {
        // Update border color based on current interface style
        publicKeyTextView.layer.borderColor = UIColor.separator.cgColor
        
        // Update text colors to ensure readability in both modes
        titleLabel.textColor = .label
        publicKeyTextView.textColor = .label
        publicKeyTextView.backgroundColor = .systemBackground
    }
    
    @objc private func importButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func importToConversationsTapped() {
        guard !publicKeyTextView.text.isEmpty else {
            showAlert(title: "Error", message: "Please import a public key first")
            return
        }
        
        let alert = UIAlertController(title: "New Conversation", message: "Enter name for the conversation", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Conversation name"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self?.addConversation(name: name)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func addConversation(name: String) {
        let contact = ContactPGP(name: name,
                             publicKey: publicKeyTextView.text,
                             messages: [],
                             messageDates: [])
        
        var contacts = UserDefaults.standard.contacts
        contacts.append(contact)
        UserDefaults.standard.contacts = contacts
        
        delegate?.didAddNewConversation()
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AddConversationViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            let data = try String(contentsOf: url)
            publicKeyTextView.text = data
        } catch {
            showAlert(title: "Error", message: "Failed to read file: \(error.localizedDescription)")
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    var contacts: [ContactPGP] {
        get {
            guard let data = self.data(forKey: "contacts") else { return [] }
            return (try? JSONDecoder().decode([ContactPGP].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                self.set(data, forKey: "contacts")
            }
        }
    }
    
    func migrateContactsIfNeeded() {
        var contacts = self.contacts
        // This will trigger the custom decoder in Contact which assigns IDs if missing.
        if !contacts.isEmpty {
            self.contacts = contacts
        }
    }
}

