import UIKit

class PasswordGeneratorViewController: UIViewController {
    
    // UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let passwordLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .monospacedSystemFont(ofSize: 20, weight: .medium)
        label.backgroundColor = .secondarySystemBackground
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()
    
    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    private let passwordLengthLabel: UILabel = {
        let label = UILabel()
        label.text = "Password Length: 12"
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let lengthSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 6
        slider.maximumValue = 64
        slider.value = 12
        return slider
    }()
    
    // Character Set Switches
    private let uppercaseSwitch = UISwitch()
    private let lowercaseSwitch = UISwitch()
    private let numbersSwitch = UISwitch()
    private let symbolsSwitch = UISwitch()
    
    // Pronounceable Option
    private let pronounceableSwitch = UISwitch()
    
    // Pattern-based Generation
    private let patternTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Pattern (e.g., Aaa#000!)"
        field.borderStyle = .roundedRect
        field.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        return field
    }()
    
    private let usePatternSwitch = UISwitch()
    
    // Custom character sets
    private let customCharsTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Custom characters (e.g., @#$%)"
        field.borderStyle = .roundedRect
        return field
    }()
    
    private let customExcludeTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Exclude characters (e.g., Il1O0)"
        field.borderStyle = .roundedRect
        return field
    }()
    
    // Strength meter
    private let strengthMeterView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.trackTintColor = .systemGray5
        return progressView
    }()
    
    private let strengthLabel: UILabel = {
        let label = UILabel()
        label.text = "Strength: Weak"
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate", for: .normal)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        return button
    }()
    
    // Properties
    private var generatedPassword = ""
    weak var delegate: PasswordGeneratorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Password Generator"
        enableKeyboardHandling()
        setupUI()
        setupActions()
        configureInitialState()
        generatePassword()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all subviews directly to contentView
        [passwordLabel, copyButton, passwordLengthLabel, lengthSlider,
         patternTextField, customCharsTextField, customExcludeTextField,
         strengthMeterView, strengthLabel, generateButton].forEach { 
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            passwordLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            passwordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            passwordLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            passwordLabel.heightAnchor.constraint(equalToConstant: 80),
            
            copyButton.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 10),
            copyButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 100),
            copyButton.heightAnchor.constraint(equalToConstant: 40),
            
            passwordLengthLabel.topAnchor.constraint(equalTo: copyButton.bottomAnchor, constant: 30),
            passwordLengthLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            lengthSlider.topAnchor.constraint(equalTo: passwordLengthLabel.bottomAnchor, constant: 10),
            lengthSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lengthSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
        
        // Create and layout switch sections
        var previousView: UIView = lengthSlider
        let switchData = [
            ("Uppercase (A-Z)", uppercaseSwitch),
            ("Lowercase (a-z)", lowercaseSwitch),
            ("Numbers (0-9)", numbersSwitch),
            ("Symbols (!@#$%)", symbolsSwitch),
            ("Pronounceable", pronounceableSwitch),
            ("Use Pattern", usePatternSwitch)
        ]
        
        for (title, switchView) in switchData {
            let section = createSwitchSection(title, switchView)
            section.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(section)
            
            NSLayoutConstraint.activate([
                section.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 20),
                section.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                section.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                section.heightAnchor.constraint(equalToConstant: 40)
            ])
            previousView = section
        }
        
        // Pattern field
        NSLayoutConstraint.activate([
            patternTextField.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 10),
            patternTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            patternTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            patternTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Custom character sets
        let customLabel = createLabel("Custom Character Sets")
        customLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(customLabel)
        
        NSLayoutConstraint.activate([
            customLabel.topAnchor.constraint(equalTo: patternTextField.bottomAnchor, constant: 30),
            customLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            customCharsTextField.topAnchor.constraint(equalTo: customLabel.bottomAnchor, constant: 10),
            customCharsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            customCharsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            customCharsTextField.heightAnchor.constraint(equalToConstant: 40),
            
            customExcludeTextField.topAnchor.constraint(equalTo: customCharsTextField.bottomAnchor, constant: 10),
            customExcludeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            customExcludeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            customExcludeTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Strength meter
        let strengthHeader = createLabel("Password Strength")
        strengthHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(strengthHeader)
        
        NSLayoutConstraint.activate([
            strengthHeader.topAnchor.constraint(equalTo: customExcludeTextField.bottomAnchor, constant: 30),
            strengthHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            strengthMeterView.topAnchor.constraint(equalTo: strengthHeader.bottomAnchor, constant: 10),
            strengthMeterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            strengthMeterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            strengthMeterView.heightAnchor.constraint(equalToConstant: 10),
            
            strengthLabel.topAnchor.constraint(equalTo: strengthMeterView.bottomAnchor, constant: 5),
            strengthLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            strengthLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            generateButton.topAnchor.constraint(equalTo: strengthLabel.bottomAnchor, constant: 30),
            generateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            generateButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createSwitchSection(_ title: String, _ switchView: UISwitch) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        
        container.addSubview(label)
        container.addSubview(switchView)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        switchView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            switchView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            switchView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }
    
    private func setupActions() {
        generateButton.addTarget(self, action: #selector(generatePassword), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyPassword), for: .touchUpInside)
        lengthSlider.addTarget(self, action: #selector(lengthChanged), for: .valueChanged)
        
        // Switch actions
        [uppercaseSwitch, lowercaseSwitch, numbersSwitch, symbolsSwitch, pronounceableSwitch, usePatternSwitch].forEach {
            $0.addTarget(self, action: #selector(optionChanged), for: .valueChanged)
        }
        
        // Text field delegates
        patternTextField.delegate = self
        customCharsTextField.delegate = self
        customExcludeTextField.delegate = self
        
        // Add dismiss button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissTapped)
        )
        
        // Add use button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Use",
            style: .done,
            target: self,
            action: #selector(usePassword)
        )
    }
    
    private func configureInitialState() {
        uppercaseSwitch.isOn = true
        lowercaseSwitch.isOn = true
        numbersSwitch.isOn = true
        symbolsSwitch.isOn = false
        pronounceableSwitch.isOn = false
        usePatternSwitch.isOn = false
        patternTextField.isHidden = true
    }
    
    @objc private func generatePassword() {
        if usePatternSwitch.isOn {
            generatedPassword = generatePatternBasedPassword()
        } else if pronounceableSwitch.isOn {
            generatedPassword = generatePronounceablePassword()
        } else {
            generatedPassword = generateRandomPassword()
        }
        
        passwordLabel.text = generatedPassword
        updatePasswordStrength()
    }
    
    private func generateRandomPassword() -> String {
        var characterSet = ""
        
        if uppercaseSwitch.isOn {
            characterSet += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        if lowercaseSwitch.isOn {
            characterSet += "abcdefghijklmnopqrstuvwxyz"
        }
        if numbersSwitch.isOn {
            characterSet += "0123456789"
        }
        if symbolsSwitch.isOn {
            characterSet += "!@#$%^&*()-_=+[]{}|;:'\",.<>?"
        }
        
        // Add custom characters
        if let custom = customCharsTextField.text, !custom.isEmpty {
            characterSet += custom
        }
        
        // Remove excluded characters
        if let excluded = customExcludeTextField.text, !excluded.isEmpty {
            for char in excluded {
                characterSet = characterSet.replacingOccurrences(of: String(char), with: "")
            }
        }
        
        guard !characterSet.isEmpty else { return "" }
        
        let length = Int(lengthSlider.value)
        var password = ""
        
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<characterSet.count)
            let index = characterSet.index(characterSet.startIndex, offsetBy: randomIndex)
            password.append(characterSet[index])
        }
        
        return password
    }
    
    private func generatePronounceablePassword() -> String {
        let consonants = "bcdfghjklmnpqrstvwxyz"
        let vowels = "aeiou"
        let numbers = "0123456789"
        let symbols = "!@#$%"
        
        let length = Int(lengthSlider.value)
        var password = ""
        var useConsonant = Bool.random()
        
        for i in 0..<length {
            if i == length - 3 && numbersSwitch.isOn {
                // Add numbers at the end
                for _ in 0..<2 {
                    let index = Int.random(in: 0..<numbers.count)
                    password.append(numbers[numbers.index(numbers.startIndex, offsetBy: index)])
                }
                break
            } else if i == length - 1 && symbolsSwitch.isOn {
                // Add symbol at the end
                let index = Int.random(in: 0..<symbols.count)
                password.append(symbols[symbols.index(symbols.startIndex, offsetBy: index)])
            } else {
                let chars = useConsonant ? consonants : vowels
                let index = Int.random(in: 0..<chars.count)
                var char = chars[chars.index(chars.startIndex, offsetBy: index)]
                
                // Randomly capitalize
                if uppercaseSwitch.isOn && Bool.random() {
                    char = Character(char.uppercased())
                }
                
                password.append(char)
                useConsonant.toggle()
            }
        }
        
        return password
    }
    
    private func generatePatternBasedPassword() -> String {
        guard let pattern = patternTextField.text, !pattern.isEmpty else {
            return generateRandomPassword()
        }
        
        var password = ""
        
        for char in pattern {
            switch char {
            case "A":
                password.append(randomCharacter(from: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
            case "a":
                password.append(randomCharacter(from: "abcdefghijklmnopqrstuvwxyz"))
            case "0", "#":
                password.append(randomCharacter(from: "0123456789"))
            case "!":
                password.append(randomCharacter(from: "!@#$%^&*()-_=+"))
            default:
                password.append(char)
            }
        }
        
        return password
    }
    
    private func randomCharacter(from string: String) -> Character {
        let index = Int.random(in: 0..<string.count)
        return string[string.index(string.startIndex, offsetBy: index)]
    }
    
    private func updatePasswordStrength() {
        let strength = calculatePasswordStrength(generatedPassword)
        
        strengthMeterView.progress = Float(strength) / 100.0
        
        if strength < 30 {
            strengthMeterView.progressTintColor = .systemRed
            strengthLabel.text = "Strength: Weak"
        } else if strength < 60 {
            strengthMeterView.progressTintColor = .systemOrange
            strengthLabel.text = "Strength: Fair"
        } else if strength < 80 {
            strengthMeterView.progressTintColor = .systemYellow
            strengthLabel.text = "Strength: Good"
        } else {
            strengthMeterView.progressTintColor = .systemGreen
            strengthLabel.text = "Strength: Strong"
        }
    }
    
    private func calculatePasswordStrength(_ password: String) -> Int {
        var strength = 0
        
        // Length
        strength += min(password.count * 4, 40)
        
        // Character variety
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            strength += 10
        }
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            strength += 10
        }
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            strength += 10
        }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
            strength += 15
        }
        
        // Entropy bonus
        let uniqueChars = Set(password).count
        strength += min(uniqueChars * 2, 15)
        
        return min(strength, 100)
    }
    
    @objc private func copyPassword() {
        UIPasteboard.general.string = generatedPassword
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.copyButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.copyButton.transform = .identity
                self.copyButton.setTitle("Copied!", for: .normal)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.copyButton.setTitle("Copy", for: .normal)
        }
    }
    
    @objc private func lengthChanged() {
        let length = Int(lengthSlider.value)
        passwordLengthLabel.text = "Password Length: \(length)"
        generatePassword()
    }
    
    @objc private func optionChanged(_ sender: UISwitch) {
        if sender == pronounceableSwitch {
            if pronounceableSwitch.isOn {
                usePatternSwitch.isOn = false
                patternTextField.isHidden = true
            }
        } else if sender == usePatternSwitch {
            if usePatternSwitch.isOn {
                pronounceableSwitch.isOn = false
                patternTextField.isHidden = false
            } else {
                patternTextField.isHidden = true
            }
        }
        generatePassword()
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    @objc private func usePassword() {
        delegate?.didSelectPassword(generatedPassword)
        dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension PasswordGeneratorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        generatePassword()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        generatePassword()
    }
}

// MARK: - Protocol
protocol PasswordGeneratorDelegate: AnyObject {
    func didSelectPassword(_ password: String)
}