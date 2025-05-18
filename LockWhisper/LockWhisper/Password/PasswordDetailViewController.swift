import UIKit

// MARK: - PasswordDetailViewControllerDelegate Protocol

protocol PasswordDetailViewControllerDelegate: AnyObject {
    func didSavePassword(entry: PasswordEntry, at index: Int?)
}

// MARK: - PasswordDetailViewController

class PasswordDetailViewController: UIViewController {
    
    weak var delegate: PasswordDetailViewControllerDelegate?
    
    // When nil, we're adding a new password; when non-nil, we're editing.
    var passwordEntry: PasswordEntry?
    // Holds the index of the entry if in edit mode.
    var entryIndex: Int?
    
    // Two text fields for entering the title and the password.
    let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Title"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.isSecureTextEntry = true // Show dots instead of actual characters
        return tf
    }()
    
    // Toggle button to show/hide password
    let togglePasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Generate password button
    let generatePasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // Title will reflect if we are adding or editing.
        title = passwordEntry == nil ? "Add Password" : "Edit Password"
        setupNavigationBar()
        setupUI()
        // Pre-fill fields if editing.
        if let entry = passwordEntry {
            titleTextField.text = entry.title
            passwordTextField.text = entry.password
        }
        
        // Add target to toggle password visibility
        togglePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        // Add target to generate password
        generatePasswordButton.addTarget(self, action: #selector(generatePasswordTapped), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupUI() {
        view.addSubview(titleTextField)
        view.addSubview(passwordTextField)
        view.addSubview(togglePasswordButton)
        view.addSubview(generatePasswordButton)
        
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            passwordTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: togglePasswordButton.leadingAnchor, constant: -8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            
            togglePasswordButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor),
            togglePasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            togglePasswordButton.widthAnchor.constraint(equalToConstant: 60),
            
            generatePasswordButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 15),
            generatePasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generatePasswordButton.widthAnchor.constraint(equalToConstant: 120),
            generatePasswordButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        togglePasswordButton.setTitle(passwordTextField.isSecureTextEntry ? "Show" : "Hide", for: .normal)
    }
    
    @objc private func generatePasswordTapped() {
        let generatorVC = PasswordGeneratorViewController()
        generatorVC.delegate = self
        let navController = UINavigationController(rootViewController: generatorVC)
        present(navController, animated: true)
    }
    
    @objc private func saveTapped() {
        // Validate that both fields have content.
        guard let titleText = titleTextField.text, !titleText.isEmpty,
              let passwordText = passwordTextField.text, !passwordText.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Both fields are required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let newEntry = PasswordEntry(title: titleText, password: passwordText)
        // Call the delegate to handle adding/updating.
        delegate?.didSavePassword(entry: newEntry, at: entryIndex)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - PasswordGeneratorDelegate
extension PasswordDetailViewController: PasswordGeneratorDelegate {
    func didSelectPassword(_ password: String) {
        passwordTextField.text = password
    }
}
