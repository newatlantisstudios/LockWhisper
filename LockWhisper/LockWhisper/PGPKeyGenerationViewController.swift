import UIKit

protocol PGPKeyGenerationDelegate: AnyObject {
    func didRequestKeyGeneration(name: String, email: String, passphrase: String)
    func didCancelKeyGeneration()
}

class PGPKeyGenerationViewController: UIViewController {
    weak var delegate: PGPKeyGenerationDelegate?

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name (e.g., John Doe)"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email (e.g., johndoe@example.com)"
        tf.keyboardType = .emailAddress
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let passphraseField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Passphrase"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [nameField, emailField, passphraseField, errorLabel, generateButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    @objc private func generateTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let email = emailField.text, !email.isEmpty,
              let passphrase = passphraseField.text, !passphrase.isEmpty else {
            showError("All fields are required")
            return
        }
        errorLabel.isHidden = true
        delegate?.didRequestKeyGeneration(name: name, email: email, passphrase: passphrase)
    }

    @objc private func cancelTapped() {
        delegate?.didCancelKeyGeneration()
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}
