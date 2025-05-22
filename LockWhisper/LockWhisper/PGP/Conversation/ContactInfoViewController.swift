import UIKit

class ContactInfoViewController: UIViewController {
    private var contact: ContactPGP
    weak var delegate: ContactInfoDelegate?
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.text = "Nickname"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nicknameTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let publicKeyLabel: UILabel = {
        let label = UILabel()
        label.text = "PGP Public Key"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let publicKeyTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let saveNicknameButton: StyledButton = {
        let button = StyledButton()
        button.setTitle("Save Nickname", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setStyle(.primary)
        button.addTarget(self, action: #selector(saveNicknameTapped), for: .touchUpInside)
        return button
    }()
    
    private let savePublicKeyButton: StyledButton = {
        let button = StyledButton()
        button.setTitle("Save PGP Public Key", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setStyle(.primary)
        button.addTarget(self, action: #selector(savePublicKeyTapped), for: .touchUpInside)
        return button
    }()
    
    init(contact: ContactPGP) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        enableKeyboardHandling()
        setupUI()
        updateUI()
    }
    
    private func setupUI() {
        view.addSubview(nicknameLabel)
        view.addSubview(nicknameTextView)
        view.addSubview(publicKeyLabel)
        view.addSubview(publicKeyTextView)
        view.addSubview(saveNicknameButton)
        view.addSubview(savePublicKeyButton)
        
        updateInterfaceColors()
        
        NSLayoutConstraint.activate([
            nicknameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nicknameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nicknameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            nicknameTextView.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 8),
            nicknameTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nicknameTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nicknameTextView.heightAnchor.constraint(equalToConstant: 40),
            
            publicKeyLabel.topAnchor.constraint(equalTo: nicknameTextView.bottomAnchor, constant: 20),
            publicKeyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            publicKeyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            publicKeyTextView.topAnchor.constraint(equalTo: publicKeyLabel.bottomAnchor, constant: 8),
            publicKeyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            publicKeyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            publicKeyTextView.heightAnchor.constraint(equalToConstant: 200),
            
            saveNicknameButton.topAnchor.constraint(equalTo: publicKeyTextView.bottomAnchor, constant: 20),
            saveNicknameButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveNicknameButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveNicknameButton.heightAnchor.constraint(equalToConstant: 44),
            
            savePublicKeyButton.topAnchor.constraint(equalTo: saveNicknameButton.bottomAnchor, constant: 12),
            savePublicKeyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            savePublicKeyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            savePublicKeyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func updateInterfaceColors() {
        // Update text colors for labels
        nicknameLabel.textColor = .label
        publicKeyLabel.textColor = .label
        
        // Update text views
        nicknameTextView.textColor = .label
        nicknameTextView.backgroundColor = .systemBackground
        nicknameTextView.layer.borderColor = UIColor.separator.cgColor
        
        publicKeyTextView.textColor = .label
        publicKeyTextView.backgroundColor = .systemBackground
        publicKeyTextView.layer.borderColor = UIColor.separator.cgColor
    }
    
    private func updateUI() {
        nicknameTextView.text = contact.name
        publicKeyTextView.text = contact.publicKey
        updateInterfaceColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateInterfaceColors()
        }
    }
    
    @objc private func saveNicknameTapped() {
        let contacts = UserDefaults.standard.contacts
        if let index = contacts.firstIndex(where: { $0.name == contact.name }) {
            var updatedContacts = contacts
            updatedContacts[index].name = nicknameTextView.text
            UserDefaults.standard.contacts = updatedContacts
            contact = updatedContacts[index]
            delegate?.contactDidUpdate(contact)
            showAlert(message: "Nickname saved successfully!")
        }
    }
    
    @objc private func savePublicKeyTapped() {
        let contacts = UserDefaults.standard.contacts
        if let index = contacts.firstIndex(where: { $0.name == contact.name }) {
            var updatedContacts = contacts
            updatedContacts[index].publicKey = publicKeyTextView.text
            UserDefaults.standard.contacts = updatedContacts
            contact = updatedContacts[index]
            showAlert(message: "Public key saved successfully!")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
