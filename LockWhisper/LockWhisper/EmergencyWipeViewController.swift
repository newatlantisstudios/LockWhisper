import UIKit
import LocalAuthentication

class EmergencyWipeViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "Emergency Data Wipe"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = """
        This will permanently delete ALL data stored in LockWhisper including:
        • All encrypted messages
        • Notes and passwords
        • Files and media
        • Contact information
        • PGP keys
        
        This action CANNOT be undone!
        """
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emergencyWipeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Emergency Wipe", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(warningLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(emergencyWipeButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 30),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            emergencyWipeButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 50),
            emergencyWipeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emergencyWipeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            emergencyWipeButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: emergencyWipeButton.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupActions() {
        emergencyWipeButton.addTarget(self, action: #selector(emergencyWipeTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func emergencyWipeTapped() {
        showConfirmationAlert()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Confirmation
    
    private func showConfirmationAlert() {
        let alert = UIAlertController(
            title: "Confirm Emergency Wipe",
            message: "Are you absolutely sure? This will permanently delete ALL data and cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        let wipeAction = UIAlertAction(title: "Wipe All Data", style: .destructive) { [weak self] _ in
            self?.showFinalConfirmation()
        }
        
        alert.addAction(wipeAction)
        present(alert, animated: true)
    }
    
    private func showFinalConfirmation() {
        let alert = UIAlertController(
            title: "Final Confirmation",
            message: "Type 'DELETE' to confirm emergency data wipe",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Type DELETE"
            textField.autocapitalizationType = .allCharacters
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { [weak self, weak alert] _ in
            guard let textField = alert?.textFields?.first,
                  textField.text == "DELETE" else {
                self?.showInvalidConfirmationAlert()
                return
            }
            
            self?.performEmergencyWipe()
        }
        
        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
    
    private func showInvalidConfirmationAlert() {
        let alert = UIAlertController(
            title: "Invalid Confirmation",
            message: "You must type 'DELETE' exactly to confirm the emergency wipe.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func performEmergencyWipe() {
        // Show progress
        let progressAlert = UIAlertController(
            title: "Wiping Data",
            message: "Please wait...",
            preferredStyle: .alert
        )
        present(progressAlert, animated: true)
        
        // Perform emergency wipe
        AutoDestructManager.shared.manualTrigger { [weak self] success in
            if success {
                // Data wipe successful - app will terminate
                print("Emergency data wipe completed")
            } else {
                // Show error
                progressAlert.dismiss(animated: true) {
                    self?.showErrorAlert()
                }
            }
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to perform emergency data wipe. Please try again.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}