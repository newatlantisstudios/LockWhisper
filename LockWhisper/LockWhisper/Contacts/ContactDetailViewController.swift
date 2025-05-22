import UIKit
import ObjectiveC

// Protocol to inform the delegate (typically ContactsViewController) about updates.
protocol ContactDetailDelegate: AnyObject {
    func didUpdateContact(_ updatedContact: ContactContacts, at index: Int)
}

class ContactDetailViewController: UIViewController {
    
    // The contact to display and edit. Must be set before the view loads.
    var contact: ContactContacts?
    // The index of this contact in the list. Useful for updating.
    var contactIndex: Int?
    // Delegate to pass back the updated contact.
    weak var delegate: ContactDetailDelegate?
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        // Editable by default.
        return tf
    }()
    
    private let email1TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email 1"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let email2TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email 2"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let phone1TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Phone 1"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let phone2TextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Phone 2"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let notesTextView: UITextView = {
        let tv = UITextView()
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 8
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        // Editable by default.
        return tv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Contact"
        view.backgroundColor = .systemBackground
        enableKeyboardHandling()
        
        setupNavigationBar()
        setupUI()
        populateData()
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBar() {
        // Add a Save button to update the contact.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveContact)
        )
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all input fields to the content view.
        [nameTextField,
         email1TextField,
         email2TextField,
         phone1TextField,
         phone2TextField,
         notesTextView].forEach { contentView.addSubview($0) }
        
        // Set constraints for scrollView and contentView.
        NSLayoutConstraint.activate([
            // ScrollView fills the view.
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView fills the scrollView.
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Layout the fields vertically with padding.
        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            email1TextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: padding),
            email1TextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            email1TextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            email1TextField.heightAnchor.constraint(equalToConstant: 44),
            
            email2TextField.topAnchor.constraint(equalTo: email1TextField.bottomAnchor, constant: padding),
            email2TextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            email2TextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            email2TextField.heightAnchor.constraint(equalToConstant: 44),
            
            phone1TextField.topAnchor.constraint(equalTo: email2TextField.bottomAnchor, constant: padding),
            phone1TextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            phone1TextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            phone1TextField.heightAnchor.constraint(equalToConstant: 44),
            
            phone2TextField.topAnchor.constraint(equalTo: phone1TextField.bottomAnchor, constant: padding),
            phone2TextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            phone2TextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            phone2TextField.heightAnchor.constraint(equalToConstant: 44),
            
            notesTextView.topAnchor.constraint(equalTo: phone2TextField.bottomAnchor, constant: padding),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            notesTextView.heightAnchor.constraint(equalToConstant: 150),
            notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func populateData() {
        // Pre-fill the fields with the contact data.
        guard let contact = contact else { return }
        nameTextField.text = contact.name
        email1TextField.text = contact.email1
        email2TextField.text = contact.email2
        phone1TextField.text = contact.phone1
        phone2TextField.text = contact.phone2
        notesTextView.text = contact.notes
    }
    
    // MARK: - Actions
    
    @objc private func saveContact() {
        // Validate that at least the name is provided.
        guard let name = nameTextField.text, !name.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Name cannot be empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Create an updated contact.
        let updatedContact = ContactContacts(
            name: name,
            email1: email1TextField.text,
            email2: email2TextField.text,
            phone1: phone1TextField.text,
            phone2: phone2TextField.text,
            notes: notesTextView.text
        )
        
        // Inform the delegate about the update.
        if let index = contactIndex {
            delegate?.didUpdateContact(updatedContact, at: index)
        }
        
        // Pop back to the previous screen.
        navigationController?.popViewController(animated: true)
    }
}
