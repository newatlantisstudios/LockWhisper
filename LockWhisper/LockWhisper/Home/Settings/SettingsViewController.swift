// Define error types only for our internal use (these won't conflict with existing types)
enum MigrationCryptoError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case unsupportedVersion(UInt8)
}

enum MigrationKeychainError: Error {
    case unhandledError(status: OSStatus)
}

import UIKit
import LocalAuthentication
import ZipArchive
import CryptoKit
import CoreData

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // A switch to toggle biometric authentication.
    private let biometricSwitch: UISwitch = {
       let biometricSwitch = UISwitch()
       biometricSwitch.translatesAutoresizingMaskIntoConstraints = false
       biometricSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.biometricEnabled)
       return biometricSwitch
    }()
    
    // A switch to toggle unencrypted fallback
    private let fallbackSwitch: UISwitch = {
        let fallbackSwitch = UISwitch()
        fallbackSwitch.translatesAutoresizingMaskIntoConstraints = false
        fallbackSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.allowUnencryptedFallback)
        return fallbackSwitch
    }()
    
    // A switch to toggle auto-destruct
    private let autoDestructSwitch: UISwitch = {
        let autoDestructSwitch = UISwitch()
        autoDestructSwitch.translatesAutoresizingMaskIntoConstraints = false
        autoDestructSwitch.isOn = UserDefaults.standard.bool(forKey: Constants.autoDestructEnabled)
        return autoDestructSwitch
    }()
    
    // Timer properties for auto-destruct toggle
    private var autoDestructTimer: Timer?
    private var timerLabel: UILabel?
    private var cancelButton: UIButton?
    
    // Stepper for attempt limit
    private let attemptLimitStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.minimumValue = 3
        stepper.maximumValue = 10
        stepper.stepValue = 1
        let savedValue = UserDefaults.standard.integer(forKey: Constants.maxFailedAttempts)
        stepper.value = Double(savedValue > 0 ? savedValue : Constants.defaultMaxFailedAttempts)
        return stepper
    }()
    
    private let attemptLimitLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        let savedValue = UserDefaults.standard.integer(forKey: Constants.maxFailedAttempts)
        let currentValue = savedValue > 0 ? savedValue : Constants.defaultMaxFailedAttempts
        label.text = "\(currentValue) attempts"
        return label
    }()
    
    // A segmented control for biometric check intervals
    private let biometricIntervalControl: UISegmentedControl = {
        let items = ["Never", "5 min", "10 min", "30 min", "1 hr"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        
        // Set default interval: 0=Never, 1=5min, 2=10min, 3=30min, 4=1hr
        let savedInterval = UserDefaults.standard.integer(forKey: Constants.biometricCheckInterval)
        let intervals = [0, 5, 10, 30, 60]
        if let index = intervals.firstIndex(of: savedInterval) {
            control.selectedSegmentIndex = index
        } else {
            control.selectedSegmentIndex = 0 // Default to "Never"
        }
        
        return control
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Settings"
        setupNavigationBar()
        setupScrollView()
        setupBiometricSwitch()
        setupMigrationButtons() // Add migration buttons
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBar() {
        // Create the tip jar button using the image named "tipJar" with smaller size
        if let originalImage = UIImage(named: "tipJar") {
            let targetSize = CGSize(width: 32, height: 32)
            let tipJarImage = resizeImage(image: originalImage, targetSize: targetSize)
            let tipJarButton = UIBarButtonItem(image: tipJarImage, style: .plain, target: self, action: #selector(tipJarTapped))
            navigationItem.rightBarButtonItem = tipJarButton
        }
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupBiometricSwitch() {
        let biometricLabel = UILabel()
        biometricLabel.text = "Enable Biometric Authentication"
        biometricLabel.font = UIFont.systemFont(ofSize: 16)
        biometricLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add both the label and the switch to the content view.
        contentView.addSubview(biometricLabel)
        contentView.addSubview(biometricSwitch)

        // Add target to update the stored preference when the switch toggles.
        biometricSwitch.addTarget(self, action: #selector(biometricSwitchToggled(_:)), for: .valueChanged)
        
        // Place the switch and label at the top of the content view.
        NSLayoutConstraint.activate([
            biometricLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            biometricLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            biometricSwitch.centerYAnchor.constraint(equalTo: biometricLabel.centerYAnchor),
            biometricSwitch.leadingAnchor.constraint(equalTo: biometricLabel.trailingAnchor, constant: 16)
        ])

        // Add fallback label and switch below biometric
        let fallbackLabel = UILabel()
        fallbackLabel.text = "Allow Unencrypted Fallback (Not Recommended)"
        fallbackLabel.font = UIFont.systemFont(ofSize: 16)
        fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fallbackLabel)
        contentView.addSubview(fallbackSwitch)
        fallbackSwitch.addTarget(self, action: #selector(fallbackSwitchToggled(_:)), for: .valueChanged)
        NSLayoutConstraint.activate([
            fallbackLabel.topAnchor.constraint(equalTo: biometricLabel.bottomAnchor, constant: 24),
            fallbackLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fallbackSwitch.centerYAnchor.constraint(equalTo: fallbackLabel.centerYAnchor),
            fallbackSwitch.leadingAnchor.constraint(equalTo: fallbackLabel.trailingAnchor, constant: 16)
        ])
        
        // Add biometric check interval controls
        let intervalLabel = UILabel()
        intervalLabel.text = "Re-authentication Interval"
        intervalLabel.font = UIFont.systemFont(ofSize: 16)
        intervalLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(intervalLabel)
        contentView.addSubview(biometricIntervalControl)
        biometricIntervalControl.addTarget(self, action: #selector(biometricIntervalChanged(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            intervalLabel.topAnchor.constraint(equalTo: fallbackLabel.bottomAnchor, constant: 24),
            intervalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            intervalLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            biometricIntervalControl.topAnchor.constraint(equalTo: intervalLabel.bottomAnchor, constant: 12),
            biometricIntervalControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            biometricIntervalControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        // Initially hide interval control if biometric is disabled
        updateBiometricIntervalVisibility()
        
        // Add auto-destruct toggle
        setupAutoDestructToggle()
    }
    
    // MARK: - Actions
    
    @objc private func tipJarTapped() {
        let tipJarVC = TipJarViewController()
        navigationController?.pushViewController(tipJarVC, animated: true)
    }
    
    @objc private func biometricSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Constants.biometricEnabled)
        updateBiometricIntervalVisibility()
    }
    
    @objc private func fallbackSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Constants.allowUnencryptedFallback)
    }
    
    @objc private func biometricIntervalChanged(_ sender: UISegmentedControl) {
        let intervals = [0, 5, 10, 30, 60] // In minutes
        let selectedInterval = intervals[sender.selectedSegmentIndex]
        UserDefaults.standard.set(selectedInterval, forKey: Constants.biometricCheckInterval)
        
        // Clear last auth time when interval changes
        UserDefaults.standard.removeObject(forKey: Constants.lastBiometricAuthTime)
    }
    
    private func updateBiometricIntervalVisibility() {
        let isBiometricEnabled = UserDefaults.standard.bool(forKey: Constants.biometricEnabled)
        biometricIntervalControl.isEnabled = isBiometricEnabled
        biometricIntervalControl.alpha = isBiometricEnabled ? 1.0 : 0.5
    }
    
    // MARK: - Auto-Destruct Setup
    
    private func setupAutoDestructToggle() {
        let autoDestructLabel = UILabel()
        let savedValue = UserDefaults.standard.integer(forKey: Constants.maxFailedAttempts)
        let currentValue = savedValue > 0 ? savedValue : Constants.defaultMaxFailedAttempts
        autoDestructLabel.text = "Enable Auto-Destruct (\(currentValue) Failed Attempts)"
        autoDestructLabel.font = UIFont.systemFont(ofSize: 16)
        autoDestructLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(autoDestructLabel)
        contentView.addSubview(autoDestructSwitch)
        
        autoDestructSwitch.addTarget(self, action: #selector(autoDestructSwitchToggled(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            autoDestructLabel.topAnchor.constraint(equalTo: biometricIntervalControl.bottomAnchor, constant: 24),
            autoDestructLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            autoDestructSwitch.centerYAnchor.constraint(equalTo: autoDestructLabel.centerYAnchor),
            autoDestructSwitch.leadingAnchor.constraint(equalTo: autoDestructLabel.trailingAnchor, constant: 16)
        ])
        
        // Add attempt limit controls
        let attemptLimitContainer = UIView()
        attemptLimitContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(attemptLimitContainer)
        
        let attemptLimitDescLabel = UILabel()
        attemptLimitDescLabel.text = "Failed Attempts Limit:"
        attemptLimitDescLabel.font = UIFont.systemFont(ofSize: 16)
        attemptLimitDescLabel.translatesAutoresizingMaskIntoConstraints = false
        attemptLimitContainer.addSubview(attemptLimitDescLabel)
        
        attemptLimitContainer.addSubview(attemptLimitLabel)
        attemptLimitContainer.addSubview(attemptLimitStepper)
        
        attemptLimitStepper.addTarget(self, action: #selector(attemptLimitStepperChanged(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            attemptLimitContainer.topAnchor.constraint(equalTo: autoDestructLabel.bottomAnchor, constant: 16),
            attemptLimitContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            attemptLimitContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            attemptLimitContainer.heightAnchor.constraint(equalToConstant: 44),
            
            attemptLimitDescLabel.centerYAnchor.constraint(equalTo: attemptLimitContainer.centerYAnchor),
            attemptLimitDescLabel.leadingAnchor.constraint(equalTo: attemptLimitContainer.leadingAnchor),
            
            attemptLimitLabel.centerYAnchor.constraint(equalTo: attemptLimitContainer.centerYAnchor),
            attemptLimitLabel.trailingAnchor.constraint(equalTo: attemptLimitStepper.leadingAnchor, constant: -8),
            
            attemptLimitStepper.centerYAnchor.constraint(equalTo: attemptLimitContainer.centerYAnchor),
            attemptLimitStepper.trailingAnchor.constraint(equalTo: attemptLimitContainer.trailingAnchor)
        ])
        
        // Initially hide attempt limit controls if auto-destruct is disabled
        updateAutoDestructControlsVisibility()
        
        // Create timer label (initially hidden)
        timerLabel = UILabel()
        timerLabel?.text = ""
        timerLabel?.font = UIFont.systemFont(ofSize: 14)
        timerLabel?.textColor = .systemRed
        timerLabel?.translatesAutoresizingMaskIntoConstraints = false
        timerLabel?.isHidden = true
        
        // Create cancel button (initially hidden)
        cancelButton = UIButton(type: .system)
        cancelButton?.setTitle("Cancel", for: .normal)
        cancelButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton?.setTitleColor(.systemRed, for: .normal)
        cancelButton?.translatesAutoresizingMaskIntoConstraints = false
        cancelButton?.isHidden = true
        cancelButton?.addTarget(self, action: #selector(cancelTimerTapped), for: .touchUpInside)
        
        if let timerLabel = timerLabel, let cancelButton = cancelButton {
            contentView.addSubview(timerLabel)
            contentView.addSubview(cancelButton)
            
            NSLayoutConstraint.activate([
                timerLabel.topAnchor.constraint(equalTo: attemptLimitContainer.bottomAnchor, constant: 8),
                timerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                
                cancelButton.topAnchor.constraint(equalTo: attemptLimitContainer.bottomAnchor, constant: 8),
                cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        }
    }
    
    @objc private func autoDestructSwitchToggled(_ sender: UISwitch) {
        // Cancel any existing timer
        autoDestructTimer?.invalidate()
        autoDestructTimer = nil
        
        // Update visibility of attempt limit controls
        updateAutoDestructControlsVisibility()
        
        // Show confirmation dialog
        let currentLimit = Int(attemptLimitStepper.value)
        let title = sender.isOn ? "Enable Auto-Destruct?" : "Disable Auto-Destruct?"
        let message = sender.isOn 
            ? "This will permanently wipe all app data after \(currentLimit) failed unlock attempts. This action will take effect in 30 seconds."
            : "This will disable the auto-destruct security feature. This action will take effect in 30 seconds."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // Revert the switch
            sender.isOn = !sender.isOn
            self?.hideTimerElements()
        })
        
        alert.addAction(UIAlertAction(title: "Confirm", style: sender.isOn ? .destructive : .default) { [weak self] _ in
            self?.startAutoDestructTimer(enabling: sender.isOn)
        })
        
        present(alert, animated: true)
    }
    
    private func startAutoDestructTimer(enabling: Bool) {
        // Disable the switch during countdown
        autoDestructSwitch.isEnabled = false
        
        // Show timer elements
        timerLabel?.isHidden = false
        cancelButton?.isHidden = false
        
        var secondsRemaining = Constants.autoDestructToggleTimer
        updateTimerLabel(seconds: secondsRemaining)
        
        autoDestructTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            secondsRemaining -= 1
            
            if secondsRemaining <= 0 {
                timer.invalidate()
                self?.completeAutoDestructToggle(enabling: enabling)
            } else {
                self?.updateTimerLabel(seconds: secondsRemaining)
            }
        }
    }
    
    private func updateTimerLabel(seconds: Int) {
        timerLabel?.text = "Changes will take effect in \(seconds) seconds..."
    }
    
    private func completeAutoDestructToggle(enabling: Bool) {
        // Save the new state
        UserDefaults.standard.set(enabling, forKey: Constants.autoDestructEnabled)
        
        // Re-enable the switch
        autoDestructSwitch.isEnabled = true
        
        // Hide timer elements
        hideTimerElements()
        
        // Show success message
        let message = enabling ? "Auto-destruct has been enabled" : "Auto-destruct has been disabled"
        showAlert(title: "Success", message: message)
    }
    
    @objc private func cancelTimerTapped() {
        // Cancel the timer
        autoDestructTimer?.invalidate()
        autoDestructTimer = nil
        
        // Revert the switch
        autoDestructSwitch.isOn = !autoDestructSwitch.isOn
        
        // Re-enable the switch
        autoDestructSwitch.isEnabled = true
        
        // Hide timer elements
        hideTimerElements()
    }
    
    private func hideTimerElements() {
        timerLabel?.isHidden = true
        timerLabel?.text = ""
        cancelButton?.isHidden = true
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    @objc private func attemptLimitStepperChanged(_ sender: UIStepper) {
        let newValue = Int(sender.value)
        attemptLimitLabel.text = "\(newValue) attempts"
        UserDefaults.standard.set(newValue, forKey: Constants.maxFailedAttempts)
        
        // Update the auto-destruct label text
        let autoDestructLabel = view.subviews.first(where: { subview in
            if let label = subview as? UILabel, label.text?.contains("Enable Auto-Destruct") ?? false {
                return true
            }
            return false
        }) as? UILabel
        autoDestructLabel?.text = "Enable Auto-Destruct (\(newValue) Failed Attempts)"
    }
    
    private func updateAutoDestructControlsVisibility() {
        let isEnabled = autoDestructSwitch.isOn
        attemptLimitStepper.isEnabled = isEnabled
        attemptLimitStepper.alpha = isEnabled ? 1.0 : 0.5
        attemptLimitLabel.alpha = isEnabled ? 1.0 : 0.5
        
        if let container = attemptLimitStepper.superview {
            container.subviews.forEach { subview in
                if let label = subview as? UILabel {
                    label.alpha = isEnabled ? 1.0 : 0.5
                }
            }
        }
    }
}

// Extension to add migration features to SettingsViewController
extension SettingsViewController {
    
    // MARK: - Migration UI Setup
    
    func setupMigrationButtons() {
        // Create a label for the migration section
        let migrationLabel = UILabel()
        migrationLabel.text = "Device Migration"
        migrationLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        migrationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create export button
        let exportButton = StyledButton()
        exportButton.setTitle("Export App Data", for: .normal)
        exportButton.setStyle(.primary)
        exportButton.addTarget(self, action: #selector(exportDataTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Create import button
        let importButton = StyledButton()
        importButton.setTitle("Import App Data", for: .normal)
        importButton.setStyle(.secondary)
        importButton.addTarget(self, action: #selector(importDataTapped), for: .touchUpInside)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views to the content view
        contentView.addSubview(migrationLabel)
        contentView.addSubview(exportButton)
        contentView.addSubview(importButton)
        
        // Position the migration section below the biometric interval control
        NSLayoutConstraint.activate([
            migrationLabel.topAnchor.constraint(equalTo: biometricIntervalControl.bottomAnchor, constant: 120),
            migrationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            migrationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            exportButton.topAnchor.constraint(equalTo: migrationLabel.bottomAnchor, constant: 16),
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            exportButton.heightAnchor.constraint(equalToConstant: 44),
            
            importButton.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 12),
            importButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            importButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            importButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Add emergency wipe button
        setupEmergencyWipeButton()
    }
    
    private func setupEmergencyWipeButton() {
        // Create emergency wipe section label
        let emergencyLabel = UILabel()
        emergencyLabel.text = "Emergency Options"
        emergencyLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        emergencyLabel.textColor = .systemRed
        emergencyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create emergency wipe button
        let emergencyWipeButton = StyledButton()
        emergencyWipeButton.setTitle("Emergency Data Wipe", for: .normal)
        emergencyWipeButton.setStyle(.destructive)
        emergencyWipeButton.addTarget(self, action: #selector(emergencyWipeTapped), for: .touchUpInside)
        emergencyWipeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views
        contentView.addSubview(emergencyLabel)
        contentView.addSubview(emergencyWipeButton)
        
        // Get reference to import button
        let importButton = contentView.subviews.first(where: { ($0 as? StyledButton)?.titleLabel?.text == "Import App Data" })
        
        // Position emergency section below import button
        NSLayoutConstraint.activate([
            emergencyLabel.topAnchor.constraint(equalTo: importButton?.bottomAnchor ?? contentView.bottomAnchor, constant: 40),
            emergencyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emergencyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emergencyWipeButton.topAnchor.constraint(equalTo: emergencyLabel.bottomAnchor, constant: 16),
            emergencyWipeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emergencyWipeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emergencyWipeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Add recovery settings button
        setupRecoverySettings()
    }
    
    private func setupRecoverySettings() {
        // Create recovery settings button
        let recoveryButton = StyledButton()
        recoveryButton.setTitle("Recovery Settings", for: .normal)
        recoveryButton.setStyle(.secondary)
        recoveryButton.addTarget(self, action: #selector(recoverySettingsTapped), for: .touchUpInside)
        recoveryButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add view
        contentView.addSubview(recoveryButton)
        
        // Get reference to emergency wipe button
        let emergencyWipeButton = contentView.subviews.first(where: { ($0 as? StyledButton)?.titleLabel?.text == "Emergency Data Wipe" })
        
        // Position recovery button below emergency wipe button
        NSLayoutConstraint.activate([
            recoveryButton.topAnchor.constraint(equalTo: emergencyWipeButton?.bottomAnchor ?? contentView.bottomAnchor, constant: 12),
            recoveryButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recoveryButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recoveryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Add fake password settings button
        setupFakePasswordSettings()
    }
    
    private func setupFakePasswordSettings() {
        // Create fake password settings button
        let fakePasswordButton = StyledButton()
        fakePasswordButton.setTitle("Fake Password Settings", for: .normal)
        fakePasswordButton.setStyle(.secondary)
        fakePasswordButton.addTarget(self, action: #selector(fakePasswordSettingsTapped), for: .touchUpInside)
        fakePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add view
        contentView.addSubview(fakePasswordButton)
        
        // Get reference to recovery button
        let recoveryButton = contentView.subviews.first(where: { ($0 as? StyledButton)?.titleLabel?.text == "Recovery Settings" })
        
        // Position fake password button below recovery button and set content view bottom constraint
        NSLayoutConstraint.activate([
            fakePasswordButton.topAnchor.constraint(equalTo: recoveryButton?.bottomAnchor ?? contentView.bottomAnchor, constant: 12),
            fakePasswordButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fakePasswordButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fakePasswordButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Set content view bottom constraint to the last element
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: fakePasswordButton.bottomAnchor, constant: 20)
        ])
    }
    
    @objc private func recoverySettingsTapped() {
        let recoverySettingsVC = RecoverySettingsViewController()
        navigationController?.pushViewController(recoverySettingsVC, animated: true)
    }
    
    @objc private func fakePasswordSettingsTapped() {
        let fakePasswordSettingsVC = FakePasswordSettingsViewController()
        navigationController?.pushViewController(fakePasswordSettingsVC, animated: true)
    }
    
    // MARK: - Emergency Wipe
    
    @objc private func emergencyWipeTapped() {
        let emergencyWipeVC = EmergencyWipeViewController()
        emergencyWipeVC.modalPresentationStyle = .formSheet
        present(emergencyWipeVC, animated: true)
    }
    
    // MARK: - Export Data
    
    @objc func exportDataTapped() {
        let alert = UIAlertController(
            title: "Export App Data",
            message: "This will export all your app data for migration to another device. The data will be encrypted with a password. Continue?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.authenticateAndExport()
        })
        
        present(alert, animated: true)
    }
    
    private func authenticateAndExport() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to export app data") { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.promptForExportPassword()
                    } else if let error = error {
                        self?.showAlert(title: "Authentication Failed", message: error.localizedDescription)
                    }
                }
            }
        } else {
            // Fallback if biometric authentication is not available
            promptForExportPassword()
        }
    }
    
    private func promptForExportPassword() {
        let exportPasswordVC = ExportPasswordViewController()
        exportPasswordVC.delegate = self
        exportPasswordVC.modalPresentationStyle = .formSheet
        present(exportPasswordVC, animated: true)
    }
    
    private func performExport(withPassword password: String) {
        // Show progress indicator
        let progressAlert = UIAlertController(title: "Exporting Data", message: "Please wait...", preferredStyle: .alert)
        present(progressAlert, animated: true)
        
        // Perform the export operation in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let exportURL = try self.createMigrationPackage(password: password)
                
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        // Show success message
                        self.showAlert(title: "Export Complete", message: "Your data has been successfully exported. Choose how you'd like to save the file.") { [weak self] in
                            guard let self = self else { return }
                            
                            // Ask user if they want to share with another app or save to Files
                            let actionSheet = UIAlertController(
                                title: "Export Options",
                                message: "Choose how to handle the exported file",
                                preferredStyle: .actionSheet
                            )
                            
                            actionSheet.addAction(UIAlertAction(title: "Save to Files", style: .default) { _ in
                                self.presentFileSaver(for: exportURL)
                            })
                            
                            actionSheet.addAction(UIAlertAction(title: "Share", style: .default) { _ in
                                self.presentShareSheet(for: exportURL)
                            })
                            
                            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                                // Clean up the file if the user cancels
                                try? FileManager.default.removeItem(at: exportURL)
                            })
                            
                            // On iPad, set the popover presentation controller
                            if let popoverController = actionSheet.popoverPresentationController {
                                popoverController.sourceView = self.view
                                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                                popoverController.permittedArrowDirections = []
                            }
                            
                            self.present(actionSheet, animated: true)
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showAlert(title: "Export Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func createMigrationPackage(password: String) throws -> URL {
        // Create a temporary directory for our export files
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
        
        // 1. Export UserDefaults data
        try exportUserDefaults(to: temporaryDirectoryURL)
        
        // 2. Export CoreData for notes
        try exportCoreData(to: temporaryDirectoryURL)
        
        // 3. Export File Vault files
        try exportFileVault(to: temporaryDirectoryURL)
        
        // 4. Export Keychain items (PGP private keys, encryption keys)
        try exportKeychain(to: temporaryDirectoryURL)
        
        // 5. Create a manifest with metadata
        try createManifest(in: temporaryDirectoryURL)
        
        // Create the ZIP file
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("LockWhisper_Migration_\(Date().timeIntervalSince1970).zip")
        
        // Use your chosen zip library here - we're using a generic approach for flexibility
        if !createPasswordProtectedZip(from: temporaryDirectoryURL, to: zipURL, withPassword: password) {
            throw NSError(domain: "com.lockwhisper.migration", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to create zip archive"])
        }
        
        // Clean up the temporary directory
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        
        return zipURL
    }
    
    // Create a password-protected zip using ZipArchive
    private func createPasswordProtectedZip(from sourceDirectory: URL, to destinationURL: URL, withPassword password: String) -> Bool {
        // Use ZipArchive to create a password-protected zip
        return SSZipArchive.createZipFile(atPath: destinationURL.path,
                                         withContentsOfDirectory: sourceDirectory.path,
                                         keepParentDirectory: false,
                                         compressionLevel: 9,
                                         password: password,
                                         aes: true)
    }
    
    // Extract a password-protected zip using ZipArchive
    private func extractPasswordProtectedZip(from zipURL: URL, to directory: URL, withPassword password: String) -> Bool {
        // Use ZipArchive to extract a password-protected zip
        return SSZipArchive.unzipFile(atPath: zipURL.path,
                                     toDestination: directory.path,
                                     preserveAttributes: true,
                                     overwrite: true,
                                     password: password,
                                     error: nil,
                                     delegate: nil) // Add the delegate parameter
    }
    
    // Helper method to check if data is encrypted
    private func isEncryptedData(_ data: Data) -> Bool {
        // Check for version marker that identifies encrypted data
        return data.count > 0 && data[0] == 0x01  // Version 1
    }
    
    private func exportUserDefaults(to directory: URL) throws {
        // Get all UserDefaults keys we want to migrate
        let defaults = UserDefaults.standard
        
        // Create a directory structure for decrypted data
        var migratedData: [String: Any] = [:]
        
        // 1. Export biometric setting (not encrypted)
        migratedData[Constants.biometricEnabled] = defaults.bool(forKey: Constants.biometricEnabled)
        
        // 2. Export public PGP key (might be encrypted)
        if let publicKey = defaults.string(forKey: Constants.publicPGPKey) {
            if PGPEncryptionManager.shared.isEncryptedBase64String(publicKey) {
                do {
                    let decryptedKey = try PGPEncryptionManager.shared.decryptBase64ToString(publicKey)
                    migratedData[Constants.publicPGPKey] = decryptedKey
                } catch {
                    print("Error decrypting PGP key: \(error)")
                    migratedData[Constants.publicPGPKey] = publicKey
                }
            } else {
                migratedData[Constants.publicPGPKey] = publicKey
            }
        }
        
        // 3. Export contacts (decrypt them)
        if let contactsData = defaults.data(forKey: Constants.savedContacts) {
            do {
                if isEncryptedData(contactsData) {
                    // Get encryption key and decrypt
                    let key = try getContactsEncryptionKey()
                    let decryptedData = try decryptData(contactsData, using: key)
                    
                    // Convert to array of dictionaries for JSON compatibility
                    let contacts = try JSONDecoder().decode([ContactContacts].self, from: decryptedData)
                    var contactDicts = [[String: Any]]()
                    
                    for contact in contacts {
                        var contactDict: [String: Any] = [
                            "name": contact.name
                        ]
                        
                        if let email1 = contact.email1 { contactDict["email1"] = email1 }
                        if let email2 = contact.email2 { contactDict["email2"] = email2 }
                        if let phone1 = contact.phone1 { contactDict["phone1"] = phone1 }
                        if let phone2 = contact.phone2 { contactDict["phone2"] = phone2 }
                        if let notes = contact.notes { contactDict["notes"] = notes }
                        
                        contactDicts.append(contactDict)
                    }
                    
                    migratedData[Constants.savedContacts] = contactDicts
                } else {
                    // Handle legacy unencrypted data
                    let contacts = try JSONDecoder().decode([ContactContacts].self, from: contactsData)
                    var contactDicts = [[String: Any]]()
                    
                    for contact in contacts {
                        var contactDict: [String: Any] = [
                            "name": contact.name
                        ]
                        
                        if let email1 = contact.email1 { contactDict["email1"] = email1 }
                        if let email2 = contact.email2 { contactDict["email2"] = email2 }
                        if let phone1 = contact.phone1 { contactDict["phone1"] = phone1 }
                        if let phone2 = contact.phone2 { contactDict["phone2"] = phone2 }
                        if let notes = contact.notes { contactDict["notes"] = notes }
                        
                        contactDicts.append(contactDict)
                    }
                    
                    migratedData[Constants.savedContacts] = contactDicts
                }
            } catch {
                print("Error decrypting contacts: \(error)")
                // Include encrypted data as fallback
                migratedData["savedContacts_encrypted"] = contactsData.base64EncodedString()
            }
        }
        
        // 4. Export PGP contacts (decrypt them)
        let pgpContacts = UserDefaults.standard.contacts
        
        // Convert PGP contacts to dictionaries
        var pgpContactDicts = [[String: Any]]()
        
        for contact in pgpContacts {
            var contactDict: [String: Any] = [
                "id": contact.id.uuidString,
                "name": contact.name,
                "publicKey": contact.publicKey,
                "messages": contact.messages,
                "messageDates": contact.messageDates
            ]
            
            if let notes = contact.notes { contactDict["notes"] = notes }
            
            pgpContactDicts.append(contactDict)
        }
        
        migratedData["contacts"] = pgpContactDicts
        
        // 5. Export passwords (decrypt them)
        if let passwordsData = defaults.data(forKey: Constants.savedPasswords) {
            do {
                if PasswordEncryptionManager.shared.isEncryptedData(passwordsData) {
                    let decryptedData = try PasswordEncryptionManager.shared.decryptData(passwordsData)
                    let passwords = try JSONDecoder().decode([PasswordEntry].self, from: decryptedData)
                    
                    // Convert to array of dictionaries
                    var passwordDicts = [[String: String]]()
                    
                    for password in passwords {
                        passwordDicts.append([
                            "title": password.title,
                            "password": password.password
                        ])
                    }
                    
                    migratedData["savedPasswords"] = passwordDicts
                } else {
                    let passwords = try JSONDecoder().decode([PasswordEntry].self, from: passwordsData)
                    
                    // Convert to array of dictionaries
                    var passwordDicts = [[String: String]]()
                    
                    for password in passwords {
                        passwordDicts.append([
                            "title": password.title,
                            "password": password.password
                        ])
                    }
                    
                    migratedData["savedPasswords"] = passwordDicts
                }
            } catch {
                print("Error decrypting passwords: \(error)")
                // Include encrypted data as fallback
                migratedData["savedPasswords_encrypted"] = passwordsData.base64EncodedString()
            }
        }
        
        // Convert to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: migratedData, options: [.prettyPrinted])
        
        // Save to file
        let fileURL = directory.appendingPathComponent("user_defaults_decrypted.json")
        try jsonData.write(to: fileURL)
    }
    
    // Implementation of decryption that was in ContactsViewController
    private func decryptData(_ encryptedData: Data, using key: SymmetricKey) throws -> Data {
        // Ensure data has at least version byte
        guard encryptedData.count > 1 else {
            throw MigrationCryptoError.invalidData
        }

        // Check version
        let version = encryptedData[0]
        guard version == 0x01 else {
            throw MigrationCryptoError.unsupportedVersion(version)
        }

        // Extract encrypted data (everything after version byte)
        let sealedBoxData = encryptedData.subdata(in: 1..<encryptedData.count)

        // Create sealed box and decrypt
        let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // Implementation of ContactsKeychainManager.get from the original code
    private func getContactsKeychainData(account: String) throws -> Data? {
        let service = "com.lockwhisper.contacts"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw MigrationKeychainError.unhandledError(status: status)
        }

        return result as? Data
    }

    private func getContactsEncryptionKey() throws -> SymmetricKey {
        let keychainId = "com.lockwhisper.contacts.encryptionKey"

        // Get key data from the keychain
        guard let keyData = try getContactsKeychainData(account: keychainId)
        else {
            throw NSError(domain: "com.lockwhisper.migration", code: 4001,
                          userInfo: [NSLocalizedDescriptionKey: "Could not retrieve contacts encryption key"])
        }

        return SymmetricKey(data: keyData)
    }
    
    private func exportCoreData(to directory: URL) throws {
        // Instead of copying the encrypted database file directly,
        // export decrypted Note objects
        
        // 1. Read all Notes from CoreData
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let notes = try CoreDataManager.shared.context.fetch(fetchRequest)
        
        // 2. Create a decrypted representation (JSON array)
        var decryptedNotes: [[String: Any]] = []
        
        for note in notes {
            let storedText = note.text ?? ""
            let decryptedText: String
            
            // Decrypt if needed
            if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
                do {
                    decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                } catch {
                    print("Error decrypting note: \(error)")
                    decryptedText = storedText // Fallback to encrypted text
                }
            } else {
                decryptedText = storedText
            }
            
            decryptedNotes.append([
                "text": decryptedText,
                "createdAt": note.createdAt?.timeIntervalSince1970 ?? 0
            ])
        }
        
        // 3. Save decrypted representation to migration package
        let jsonData = try JSONSerialization.data(withJSONObject: decryptedNotes, options: [.prettyPrinted])
        try jsonData.write(to: directory.appendingPathComponent("notes_decrypted.json"))
    }
    
    private func exportFileVault(to directory: URL) throws {
        // Get the documents directory (where File Vault files are stored)
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "com.lockwhisper.migration", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        // Create destination directory
        let fileVaultDir = directory.appendingPathComponent("filevault", isDirectory: true)
        try FileManager.default.createDirectory(at: fileVaultDir, withIntermediateDirectories: true)
        
        // Get all files from the documents directory
        let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        
        // Create a metadata dictionary to store original filenames and decryption status
        var fileMetadata: [[String: Any]] = []
        
        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                // Read the file data
                let fileData = try Data(contentsOf: fileURL)
                
                // Check if file is encrypted
                if FileEncryptionManager.shared.isEncryptedData(fileData) {
                    // Decrypt the file
                    let decryptedData = try FileEncryptionManager.shared.decryptData(fileData)
                    try decryptedData.write(to: tempURL)
                    
                    // Use a unique filename for the decrypted file
                    let decryptedFilename = UUID().uuidString
                    let destinationURL = fileVaultDir.appendingPathComponent(decryptedFilename)
                    try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                    
                    // Store metadata
                    fileMetadata.append([
                        "originalName": filename,
                        "decryptedName": decryptedFilename,
                        "wasEncrypted": true
                    ])
                } else {
                    // File wasn't encrypted, just copy it
                    let destinationURL = fileVaultDir.appendingPathComponent(filename)
                    try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    
                    // Store metadata
                    fileMetadata.append([
                        "originalName": filename,
                        "decryptedName": filename,
                        "wasEncrypted": false
                    ])
                }
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
                
            } catch {
                print("Error processing file \(filename): \(error)")
                
                // If decryption fails, copy the original encrypted file as fallback
                let destinationURL = fileVaultDir.appendingPathComponent("encrypted_" + filename)
                try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                
                // Store metadata
                fileMetadata.append([
                    "originalName": filename,
                    "encryptedName": "encrypted_" + filename,
                    "wasEncrypted": true,
                    "decryptionFailed": true
                ])
            }
        }
        
        // Save metadata for reconstruction during import
        let metadataURL = fileVaultDir.appendingPathComponent("files_metadata.json")
        let metadataData = try JSONSerialization.data(withJSONObject: fileMetadata, options: [.prettyPrinted])
        try metadataData.write(to: metadataURL)
    }
    
    private func exportKeychain(to directory: URL) throws {
        // Export only the PGP private key - we're handling encryption/decryption differently now
        var keychainDict: [String: String] = [:]
        
        // PGP private key (may itself be encrypted)
        if let privateKeyEncrypted = try? KeychainHelper.shared.get(key: "privatePGPKey") {
            // Check if the private key is encrypted with our method
            if PGPEncryptionManager.shared.isEncryptedBase64String(privateKeyEncrypted) {
                do {
                    // Decrypt it for export
                    let decryptedKey = try PGPEncryptionManager.shared.decryptBase64ToString(privateKeyEncrypted)
                    keychainDict["privatePGPKey"] = decryptedKey
                } catch {
                    print("Error decrypting PGP private key: \(error)")
                    // Include the encrypted key as fallback
                    keychainDict["privatePGPKey_encrypted"] = privateKeyEncrypted
                }
            } else {
                // Just include the key as-is if it's not encrypted with our method
                keychainDict["privatePGPKey"] = privateKeyEncrypted
            }
        }
        
        // We don't need to export encryption keys anymore, since we're decrypting all data
        // before adding it to the migration package
        
        // Convert to JSON and save
        let jsonData = try JSONSerialization.data(withJSONObject: keychainDict, options: [.prettyPrinted])
        let fileURL = directory.appendingPathComponent("keychain_items.json")
        try jsonData.write(to: fileURL)
    }
    
    private func createManifest(in directory: URL) throws {
        // Create a manifest with metadata about the export
        let manifest: [String: Any] = [
            "version": "1.0",
            "appVersion": "LockWhisper V3",
            "exportDate": Date().timeIntervalSince1970,
            "deviceName": UIDevice.current.name,
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted])
        let fileURL = directory.appendingPathComponent("manifest.json")
        try jsonData.write(to: fileURL)
    }
    
    private func presentShareSheet(for fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Exclude some activity types
        activityViewController.excludedActivityTypes = [
            .assignToContact, .saveToCameraRoll, .postToTwitter, .postToFacebook,
            .postToWeibo, .print, .copyToPasteboard, .addToReadingList, .postToFlickr,
            .postToVimeo, .postToTencentWeibo
        ]
        
        // On iPad, set the popover presentation controller's source view
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func presentFileSaver(for fileURL: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
        documentPicker.shouldShowFileExtensions = true
        present(documentPicker, animated: true)
    }
    
    // MARK: - Import Data
    
    @objc func importDataTapped() {
        let alert = UIAlertController(
            title: "Import App Data",
            message: "This will import app data from a migration package. Your current data will be replaced. Continue?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.authenticateAndImport()
        })
        
        present(alert, animated: true)
    }
    
    private func authenticateAndImport() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to import app data") { [weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.presentFilePicker()
                    } else if let error = error {
                        self?.showAlert(title: "Authentication Failed", message: error.localizedDescription)
                    }
                }
            }
        } else {
            // Fallback if biometric authentication is not available
            presentFilePicker()
        }
    }
    
    private func presentFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    // MARK: - Import Processing
    
    private func processImportedFile(at url: URL) {
        // Prompt for the password to unlock the zip file
        let alert = UIAlertController(title: "Enter Password", message: "Enter the password for this migration package", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Import", style: .default) { [weak self, weak alert] _ in
            guard let password = alert?.textFields?.first?.text, !password.isEmpty else {
                self?.showAlert(title: "Error", message: "Password cannot be empty")
                return
            }
            
            self?.extractAndImport(zipURL: url, password: password)
        })
        
        present(alert, animated: true)
    }
    
    private func extractAndImport(zipURL: URL, password: String) {
        // Show progress indicator
        let progressAlert = UIAlertController(title: "Importing Data", message: "Please wait...", preferredStyle: .alert)
        present(progressAlert, animated: true)
        
        // Extract and process in the background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Create a temporary directory for extraction
                let extractionDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true)
                
                // Extract the zip
                let success = self.extractPasswordProtectedZip(from: zipURL, to: extractionDir, withPassword: password)
                
                if !success {
                    throw NSError(domain: "com.lockwhisper.migration", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Failed to extract zip file. The password may be incorrect."])
                }
                
                // Process the extracted data
                try self.importFromDirectory(extractionDir)
                
                // Clean up
                try? FileManager.default.removeItem(at: extractionDir)
                try? FileManager.default.removeItem(at: zipURL)
                
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showAlert(title: "Import Complete", message: "Data has been successfully imported.") {
                            // Restart the app or notify the app needs restarting
                            self.showRestartPrompt()
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self.showAlert(title: "Import Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func importFromDirectory(_ directory: URL) throws {
        // Verify the manifest first
        try verifyManifest(in: directory)
        
        // Import in reverse order of export
        try importKeychain(from: directory)
        try importFileVault(from: directory)
        try importCoreData(from: directory)
        try importUserDefaults(from: directory)
    }
    
    private func verifyManifest(in directory: URL) throws {
        let manifestURL = directory.appendingPathComponent("manifest.json")
        
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2002, userInfo: [NSLocalizedDescriptionKey: "Invalid migration package: missing manifest"])
        }
        
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
        
        guard let version = manifest?["version"] as? String, version == "1.0",
              let appVersion = manifest?["appVersion"] as? String, appVersion.contains("LockWhisper") else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Invalid or incompatible migration package"])
        }
    }
    
    private func importUserDefaults(from directory: URL) throws {
        let userDefaultsURL = directory.appendingPathComponent("user_defaults_decrypted.json")
        guard FileManager.default.fileExists(atPath: userDefaultsURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2004, userInfo: [NSLocalizedDescriptionKey: "Missing user defaults data in migration package"])
        }
        let jsonData = try Data(contentsOf: userDefaultsURL)
        let importedData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        guard let importedData = importedData else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2005, userInfo: [NSLocalizedDescriptionKey: "Invalid user defaults format in migration package"])
        }
        let defaults = UserDefaults.standard
        let allowFallback = UserDefaults.standard.bool(forKey: Constants.allowUnencryptedFallback)
        // 1. Handle biometric setting (simple)
        if let biometricEnabled = importedData[Constants.biometricEnabled] as? Bool {
            defaults.set(biometricEnabled, forKey: Constants.biometricEnabled)
        }
        // 2. Handle public PGP key (needs encryption)
        if let publicKey = importedData[Constants.publicPGPKey] as? String {
            do {
                // Re-encrypt the key before storing
                let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(publicKey)
                defaults.set(encryptedKey, forKey: Constants.publicPGPKey)
            } catch {
                if allowFallback {
                    // Fall back to unencrypted if encryption fails
                    defaults.set(publicKey, forKey: Constants.publicPGPKey)
                } else {
                    print("Refusing to save unencrypted public PGP key due to encryption failure.")
                }
            }
        }
        // 3. Handle contacts (needs encryption)
        if let contacts = importedData[Constants.savedContacts] as? [[String: Any]] {
            do {
                let contactsObjects = try JSONSerialization.data(withJSONObject: contacts)
                let contactsList = try JSONDecoder().decode([ContactContacts].self, from: contactsObjects)
                // Re-encrypt and save
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(contactsList)
                let key = try getOrCreateContactsEncryptionKey()
                let encryptedData = try encryptData(encodedData, using: key)
                defaults.set(encryptedData, forKey: Constants.savedContacts)
            } catch {
                print("Error encrypting imported contacts: \(error)")
                if allowFallback {
                    // Look for fallback encrypted data
                    if let encryptedData = importedData["savedContacts_encrypted"] as? String,
                       let data = Data(base64Encoded: encryptedData) {
                        defaults.set(data, forKey: Constants.savedContacts)
                    }
                } else {
                    print("Refusing to save unencrypted contacts due to encryption failure.")
                }
            }
        }
        // 4. Handle PGP contacts (use the extension setter which handles encryption)
        if let pgpContacts = importedData["contacts"] as? [[String: Any]] {
            do {
                let contactsData = try JSONSerialization.data(withJSONObject: pgpContacts)
                let contactsList = try JSONDecoder().decode([ContactPGP].self, from: contactsData)
                defaults.contacts = contactsList
            } catch {
                print("Error importing PGP contacts: \(error)")
            }
        }
        // 5. Handle passwords (needs encryption)
        if let passwords = importedData["savedPasswords"] as? [[String: Any]] {
            do {
                let passwordsData = try JSONSerialization.data(withJSONObject: passwords)
                let passwordList = try JSONDecoder().decode([PasswordEntry].self, from: passwordsData)
                // Re-encrypt and save
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(passwordList)
                let encryptedData = try PasswordEncryptionManager.shared.encryptData(encodedData)
                defaults.set(encryptedData, forKey: Constants.savedPasswords)
            } catch {
                print("Error encrypting imported passwords: \(error)")
                if allowFallback {
                    // Look for fallback encrypted data
                    if let encryptedData = importedData["savedPasswords_encrypted"] as? String,
                       let data = Data(base64Encoded: encryptedData) {
                        defaults.set(data, forKey: Constants.savedPasswords)
                    }
                } else {
                    print("Refusing to save unencrypted passwords due to encryption failure.")
                }
            }
        }
    }
    
    // Implementation of encryption for contacts re-encryption
    private func encryptData(_ data: Data, using key: SymmetricKey) throws -> Data {
        // Version marker (1 byte)
        var encryptedData = Data([0x01])

        // Generate a nonce for AES-GCM
        let nonce = try AES.GCM.Nonce()

        // Perform encryption
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        // Get combined data (nonce + ciphertext + tag)
        guard let combined = sealedBox.combined else {
            throw MigrationCryptoError.encryptionFailed
        }

        // Append encrypted data to version marker
        encryptedData.append(combined)

        return encryptedData
    }
    
    private func getOrCreateContactsEncryptionKey() throws -> SymmetricKey {
        let keychainId = "com.lockwhisper.contacts.encryptionKey"
        
        // Try to get existing key
        if let keyData = try? getContactsKeychainData(account: keychainId),
           !keyData.isEmpty {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        try saveContactsKeychainData(account: keychainId,
                                    data: newKey.withUnsafeBytes { Data($0) })
        return newKey
    }
    
    // Save data to keychain (implementation of ContactsKeychainManager.save)
    private func saveContactsKeychainData(account: String, data: Data) throws {
        let service = "com.lockwhisper.contacts"
        
        // Delete any existing item first
        try? deleteContactsKeychainData(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw MigrationKeychainError.unhandledError(status: status)
        }
    }
    
    // Delete data from keychain (implementation of ContactsKeychainManager.delete)
    private func deleteContactsKeychainData(account: String) throws {
        let service = "com.lockwhisper.contacts"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MigrationKeychainError.unhandledError(status: status)
        }
    }
    
    private func importCoreData(from directory: URL) throws {
        // Import decrypted notes instead of the database file
        let notesURL = directory.appendingPathComponent("notes_decrypted.json")
        
        guard FileManager.default.fileExists(atPath: notesURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2006, userInfo: [NSLocalizedDescriptionKey: "Missing notes data in migration package"])
        }
        
        // Load the decrypted notes
        let notesData = try Data(contentsOf: notesURL)
        let notesArray = try JSONSerialization.jsonObject(with: notesData) as? [[String: Any]]
        
        guard let notesArray = notesArray else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2007, userInfo: [NSLocalizedDescriptionKey: "Invalid notes format in migration package"])
        }
        
        // Clear existing notes from CoreData
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Note.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try context.execute(deleteRequest)
        
        let allowFallback = UserDefaults.standard.bool(forKey: Constants.allowUnencryptedFallback)
        // Create new notes with the imported data
        for noteDict in notesArray {
            guard let text = noteDict["text"] as? String else { continue }
            let note = Note(context: context)
            // Re-encrypt the note text before saving
            do {
                let encryptedText = try NoteEncryptionManager.shared.encryptStringToBase64(text)
                note.text = encryptedText
            } catch {
                if allowFallback {
                    // Fallback to unencrypted if encryption fails
                    note.text = text
                } else {
                    print("Refusing to save unencrypted note due to encryption failure.")
                }
            }
            // Set created date
            if let timestamp = noteDict["createdAt"] as? TimeInterval {
                note.createdAt = Date(timeIntervalSince1970: timestamp)
            } else {
                note.createdAt = Date()
            }
        }
        // Save the context
        CoreDataManager.shared.saveContext()
    }
    
    private func importFileVault(from directory: URL) throws {
        // Get File Vault directory
        let fileVaultDir = directory.appendingPathComponent("filevault")
        
        guard FileManager.default.fileExists(atPath: fileVaultDir.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2009, userInfo: [NSLocalizedDescriptionKey: "Missing File Vault data in migration package"])
        }
        
        // Load file metadata
        let metadataURL = fileVaultDir.appendingPathComponent("files_metadata.json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2010, userInfo: [NSLocalizedDescriptionKey: "Missing file metadata in migration package"])
        }
        
        let metadataData = try Data(contentsOf: metadataURL)
        let filesMetadata = try JSONSerialization.jsonObject(with: metadataData) as? [[String: Any]]
        
        guard let filesMetadata = filesMetadata else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2011, userInfo: [NSLocalizedDescriptionKey: "Invalid file metadata format in migration package"])
        }
        
        // Get the documents directory
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2012, userInfo: [NSLocalizedDescriptionKey: "Could not access documents directory"])
        }
        
        // Clear existing files
        let existingFiles = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        for fileURL in existingFiles {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        // Process each file according to metadata
        for fileInfo in filesMetadata {
            guard let originalName = fileInfo["originalName"] as? String else { continue }
            
            // Determine source file path
            let sourceFilename: String
            let wasEncrypted = fileInfo["wasEncrypted"] as? Bool ?? false
            let decryptionFailed = fileInfo["decryptionFailed"] as? Bool ?? false
            
            if decryptionFailed {
                // Use the encrypted backup file
                sourceFilename = fileInfo["encryptedName"] as? String ?? originalName
            } else {
                // Use the decrypted file
                sourceFilename = fileInfo["decryptedName"] as? String ?? originalName
            }
            
            let sourceURL = fileVaultDir.appendingPathComponent(sourceFilename)
            let destinationURL = documentsURL.appendingPathComponent(originalName)
            
            if wasEncrypted && !decryptionFailed {
                // File was successfully decrypted during export,
                // need to re-encrypt during import
                do {
                    let fileData = try Data(contentsOf: sourceURL)
                    let encryptedData = try FileEncryptionManager.shared.encryptData(fileData)
                    try encryptedData.write(to: destinationURL)
                } catch {
                    print("Error re-encrypting file \(originalName): \(error)")
                    
                    // Copy the file as-is as fallback
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                }
            } else {
                // Either the file wasn't encrypted originally or decryption failed,
                // just copy as-is
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            }
        }
    }
    
    private func importKeychain(from directory: URL) throws {
        // Get keychain items file
        let keychainURL = directory.appendingPathComponent("keychain_items.json")
        
        guard FileManager.default.fileExists(atPath: keychainURL.path) else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2011, userInfo: [NSLocalizedDescriptionKey: "Missing keychain data in migration package"])
        }
        
        let jsonData = try Data(contentsOf: keychainURL)
        let keychainDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String]
        
        guard let keychainDict = keychainDict else {
            throw NSError(domain: "com.lockwhisper.migration", code: 2012, userInfo: [NSLocalizedDescriptionKey: "Invalid keychain format in migration package"])
        }
        
        let allowFallback = UserDefaults.standard.bool(forKey: Constants.allowUnencryptedFallback)
        // Import PGP private key
        if let privateKey = keychainDict["privatePGPKey"] {
            // Re-encrypt the private key before saving
            do {
                let encryptedKey = try PGPEncryptionManager.shared.encryptStringToBase64(privateKey)
                try KeychainHelper.shared.save(key: "privatePGPKey", value: encryptedKey)
            } catch {
                if allowFallback {
                    // Fallback to saving unencrypted if encryption fails
                    try KeychainHelper.shared.save(key: "privatePGPKey", value: privateKey)
                } else {
                    print("Refusing to save unencrypted private key due to encryption failure.")
                }
            }
        } else if let encryptedKey = keychainDict["privatePGPKey_encrypted"] {
            // If we only have the encrypted version, save that
            try KeychainHelper.shared.save(key: "privatePGPKey", value: encryptedKey)
        }
        
        // We don't need to import encryption keys - new ones are automatically
        // generated by the various modules when needed
    }
    
    private func showRestartPrompt() {
        let alert = UIAlertController(
            title: "Restart Required",
            message: "The app needs to restart to complete the import process.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Restart Now", style: .default) { _ in
            // Simulate app restart - in a real app you might want to use UIApplication.shared.perform(...) or similar
            exit(0)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    // showAlert method is already defined above
}

// MARK: - UIDocumentPickerDelegate

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, url.startAccessingSecurityScopedResource() else {
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Make a local copy of the file before processing
        do {
            let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: temporaryURL.path) {
                try FileManager.default.removeItem(at: temporaryURL)
            }
            try FileManager.default.copyItem(at: url, to: temporaryURL)
            
            // Process the imported file
            processImportedFile(at: temporaryURL)
        } catch {
            showAlert(title: "Import Error", message: "Failed to copy the file: \(error.localizedDescription)")
        }
    }
}

// Add delegate conformance
extension SettingsViewController: ExportPasswordDelegate {
    func didSetExportPassword(_ password: String) {
        dismiss(animated: true) {
            self.performExport(withPassword: password)
        }
    }
    func didCancelExportPassword() {
        dismiss(animated: true)
    }
}
