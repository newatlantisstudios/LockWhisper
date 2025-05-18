import UIKit

class FakePasswordSettingsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    private let realPasswordSection = UIView()
    private let realPasswordLabel = UILabel()
    private let realPasswordTextField = UITextField()
    private let setRealPasswordButton = StyledButton()
    
    private let fakePasswordSection = UIView()
    private let fakePasswordLabel = UILabel()
    private let fakePasswordTextField = UITextField()
    private let fakePasswordSwitch = UISwitch()
    private let fakePasswordSwitchLabel = UILabel()
    private let setFakePasswordButton = StyledButton()
    
    private let warningLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Password Settings"
        
        // Title
        titleLabel.text = "Dual Password System"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        // Description
        descriptionLabel.text = "Set up a fake password that reveals different data when entered. The real password shows your actual data."
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        
        // Real Password Section
        realPasswordLabel.text = "Real Password"
        realPasswordLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        realPasswordTextField.placeholder = "Enter real password"
        realPasswordTextField.isSecureTextEntry = true
        realPasswordTextField.borderStyle = .roundedRect
        realPasswordTextField.backgroundColor = .secondarySystemBackground
        realPasswordTextField.autocapitalizationType = .none
        realPasswordTextField.autocorrectionType = .no
        
        setRealPasswordButton.setTitle("Set Real Password", for: .normal)
        setRealPasswordButton.setStyle(.primary)
        setRealPasswordButton.addTarget(self, action: #selector(setRealPasswordTapped), for: .touchUpInside)
        
        // Fake Password Section
        fakePasswordLabel.text = "Fake Password"
        fakePasswordLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        fakePasswordTextField.placeholder = "Enter fake password"
        fakePasswordTextField.isSecureTextEntry = true
        fakePasswordTextField.borderStyle = .roundedRect
        fakePasswordTextField.backgroundColor = .secondarySystemBackground
        fakePasswordTextField.autocapitalizationType = .none
        fakePasswordTextField.autocorrectionType = .no
        
        fakePasswordSwitchLabel.text = "Enable Fake Password"
        fakePasswordSwitchLabel.font = .systemFont(ofSize: 16)
        
        fakePasswordSwitch.isOn = FakePasswordManager.shared.isFakePasswordEnabled
        fakePasswordSwitch.addTarget(self, action: #selector(fakePasswordSwitchChanged), for: .valueChanged)
        
        setFakePasswordButton.setTitle("Set Fake Password", for: .normal)
        setFakePasswordButton.setStyle(.secondary)
        setFakePasswordButton.addTarget(self, action: #selector(setFakePasswordTapped), for: .touchUpInside)
        
        // Warning
        warningLabel.text = "⚠️ Warning: Make sure to remember both passwords. The fake password will show completely different data."
        warningLabel.font = .systemFont(ofSize: 14)
        warningLabel.textColor = .systemOrange
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center
        
        // Add to scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(realPasswordSection)
        contentView.addSubview(fakePasswordSection)
        contentView.addSubview(warningLabel)
        
        realPasswordSection.addSubview(realPasswordLabel)
        realPasswordSection.addSubview(realPasswordTextField)
        realPasswordSection.addSubview(setRealPasswordButton)
        
        fakePasswordSection.addSubview(fakePasswordLabel)
        fakePasswordSection.addSubview(fakePasswordSwitchLabel)
        fakePasswordSection.addSubview(fakePasswordSwitch)
        fakePasswordSection.addSubview(fakePasswordTextField)
        fakePasswordSection.addSubview(setFakePasswordButton)
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        realPasswordSection.translatesAutoresizingMaskIntoConstraints = false
        fakePasswordSection.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        realPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        realPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        setRealPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        fakePasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        fakePasswordSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        fakePasswordSwitch.translatesAutoresizingMaskIntoConstraints = false
        fakePasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        setFakePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Real password section
            realPasswordSection.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            realPasswordSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            realPasswordSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            realPasswordLabel.topAnchor.constraint(equalTo: realPasswordSection.topAnchor),
            realPasswordLabel.leadingAnchor.constraint(equalTo: realPasswordSection.leadingAnchor),
            
            realPasswordTextField.topAnchor.constraint(equalTo: realPasswordLabel.bottomAnchor, constant: 10),
            realPasswordTextField.leadingAnchor.constraint(equalTo: realPasswordSection.leadingAnchor),
            realPasswordTextField.trailingAnchor.constraint(equalTo: realPasswordSection.trailingAnchor),
            realPasswordTextField.heightAnchor.constraint(equalToConstant: 44),
            
            setRealPasswordButton.topAnchor.constraint(equalTo: realPasswordTextField.bottomAnchor, constant: 15),
            setRealPasswordButton.leadingAnchor.constraint(equalTo: realPasswordSection.leadingAnchor),
            setRealPasswordButton.trailingAnchor.constraint(equalTo: realPasswordSection.trailingAnchor),
            setRealPasswordButton.heightAnchor.constraint(equalToConstant: 50),
            setRealPasswordButton.bottomAnchor.constraint(equalTo: realPasswordSection.bottomAnchor),
            
            // Fake password section
            fakePasswordSection.topAnchor.constraint(equalTo: realPasswordSection.bottomAnchor, constant: 30),
            fakePasswordSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fakePasswordSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            fakePasswordLabel.topAnchor.constraint(equalTo: fakePasswordSection.topAnchor),
            fakePasswordLabel.leadingAnchor.constraint(equalTo: fakePasswordSection.leadingAnchor),
            
            fakePasswordSwitchLabel.centerYAnchor.constraint(equalTo: fakePasswordSwitch.centerYAnchor),
            fakePasswordSwitchLabel.leadingAnchor.constraint(equalTo: fakePasswordSection.leadingAnchor),
            
            fakePasswordSwitch.topAnchor.constraint(equalTo: fakePasswordLabel.bottomAnchor, constant: 10),
            fakePasswordSwitch.trailingAnchor.constraint(equalTo: fakePasswordSection.trailingAnchor),
            
            fakePasswordTextField.topAnchor.constraint(equalTo: fakePasswordSwitch.bottomAnchor, constant: 15),
            fakePasswordTextField.leadingAnchor.constraint(equalTo: fakePasswordSection.leadingAnchor),
            fakePasswordTextField.trailingAnchor.constraint(equalTo: fakePasswordSection.trailingAnchor),
            fakePasswordTextField.heightAnchor.constraint(equalToConstant: 44),
            
            setFakePasswordButton.topAnchor.constraint(equalTo: fakePasswordTextField.bottomAnchor, constant: 15),
            setFakePasswordButton.leadingAnchor.constraint(equalTo: fakePasswordSection.leadingAnchor),
            setFakePasswordButton.trailingAnchor.constraint(equalTo: fakePasswordSection.trailingAnchor),
            setFakePasswordButton.heightAnchor.constraint(equalToConstant: 50),
            setFakePasswordButton.bottomAnchor.constraint(equalTo: fakePasswordSection.bottomAnchor),
            
            // Warning
            warningLabel.topAnchor.constraint(equalTo: fakePasswordSection.bottomAnchor, constant: 20),
            warningLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            warningLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func setRealPasswordTapped() {
        guard let password = realPasswordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return
        }
        
        do {
            try FakePasswordManager.shared.setupRealPassword(password)
            showAlert(title: "Success", message: "Real password has been set")
            realPasswordTextField.text = ""
        } catch {
            showAlert(title: "Error", message: "Failed to set password: \(error.localizedDescription)")
        }
    }
    
    @objc private func setFakePasswordTapped() {
        guard let password = fakePasswordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return
        }
        
        do {
            try FakePasswordManager.shared.setupFakePassword(password)
            showAlert(title: "Success", message: "Fake password has been set")
            fakePasswordTextField.text = ""
            updateUI()
        } catch {
            showAlert(title: "Error", message: "Failed to set password: \(error.localizedDescription)")
        }
    }
    
    @objc private func fakePasswordSwitchChanged() {
        if !fakePasswordSwitch.isOn {
            // Disabling fake password
            let alert = UIAlertController(
                title: "Disable Fake Password",
                message: "This will remove the fake password and delete all fake data. Are you sure?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.fakePasswordSwitch.isOn = true
            })
            
            alert.addAction(UIAlertAction(title: "Disable", style: .destructive) { [weak self] _ in
                FakePasswordManager.shared.removeFakePassword()
                FakePasswordManager.shared.wipeFakeData()
                self?.updateUI()
            })
            
            present(alert, animated: true)
        } else {
            // Enabling fake password
            UserDefaults.standard.set(true, forKey: Constants.fakePasswordEnabled)
        }
        
        updateUI()
    }
    
    // MARK: - Helper Methods
    
    private func updateUI() {
        let isFakePasswordEnabled = FakePasswordManager.shared.isFakePasswordEnabled
        fakePasswordTextField.isEnabled = isFakePasswordEnabled
        setFakePasswordButton.isEnabled = isFakePasswordEnabled
        fakePasswordTextField.alpha = isFakePasswordEnabled ? 1.0 : 0.5
        setFakePasswordButton.alpha = isFakePasswordEnabled ? 1.0 : 0.5
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}