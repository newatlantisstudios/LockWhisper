import UIKit
import LocalAuthentication  // Needed for biometric authentication
import AVFoundation
// Add required imports for controllers
import CoreData

class DashboardViewController: UIViewController {
    
    // MARK: - Data
    
    let items = ["PGP", "Notepad", "Contacts", "File Vault", "Passwords", "Camera", "Voice Memo", "Media Library", "Calendar", "TODO"]
    let imageNames = ["pgp", "notepad", "contacts", "fileVault", "passwords", "camera", "voiceMemo", "mediaLibrary", "calendar", "todo"]
    
    // MARK: - UI Elements
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        // Adjust itemSize and spacing as needed. Traditional design respects spacing!
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 120, height: 140)
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.identifier)
        return cv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // .systemBackground automatically adapts to light and dark modes.
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupCollectionView()
    }
    
    // Check for biometric authentication every time the view appears.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkBiometricAuthentication()
    }
    
    // MARK: - Setup Methods
    
    private func setupNavigationBar() {
        // Using system image "gear" for settings
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        title = "Home"
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        collectionView.isScrollEnabled = true
    }
    
    // MARK: - Biometric Authentication
    
    private func checkBiometricAuthentication() {
        // Retrieve the user's preference. Defaults to false if not set.
        let biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
        guard biometricEnabled else { return }
        
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available.
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Authenticate to access the app") { [weak self] success, authError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication was successful; proceed as normal.
                    } else {
                        // Authentication failed. You might choose to handle this case further (e.g., lock the app).
                        let alert = UIAlertController(title: "Authentication Failed", message: "Biometric authentication was not successful. Please try again.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alert, animated: true)
                    }
                }
            }
        } else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error").")
        }
    }
    
    // MARK: - Actions
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension DashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.identifier, for: indexPath) as? ItemCell else {
            fatalError("Unable to dequeue ItemCell")
        }
        
        let imageName = imageNames[indexPath.row]
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        cell.imageView.image = image
        cell.imageView.tintColor = .label
        cell.titleLabel.text = items[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = items[indexPath.row]
        
        if selectedItem == "PGP" {
            let conversationsVC = ConversationsViewController()
            navigationController?.pushViewController(conversationsVC, animated: true)
        } else if selectedItem == "Notepad" {
            let notepadVC = NotepadViewController()
            navigationController?.pushViewController(notepadVC, animated: true)
        } else if selectedItem == "Contacts" {
            let contactsVC = ContactsViewController()
            navigationController?.pushViewController(contactsVC, animated: true)
        } else if selectedItem == "Passwords" {
            let passwordVC = PasswordViewController()
            navigationController?.pushViewController(passwordVC, animated: true)
        } else if selectedItem == "File Vault" {
            // Push the FileVaultViewController when File Vault is tapped.
            let fileVaultVC = FileVaultViewController()
            navigationController?.pushViewController(fileVaultVC, animated: true)
        } else if selectedItem == "Camera" {
            let cameraVC = CameraViewController()
            navigationController?.pushViewController(cameraVC, animated: true)
        } else if selectedItem == "Voice Memo" {
            let voiceMemoVC = VoiceMemoViewController()
            navigationController?.pushViewController(voiceMemoVC, animated: true)
        } else if selectedItem == "Media Library" {
            let mediaLibraryVC = MediaLibraryViewController()
            navigationController?.pushViewController(mediaLibraryVC, animated: true)
        } else if selectedItem == "Calendar" {
            let calendarVC = CalendarViewController()
            navigationController?.pushViewController(calendarVC, animated: true)
        } else if selectedItem == "TODO" {
            let todoVC = TODOViewController()
            navigationController?.pushViewController(todoVC, animated: true)
        }
    }
}

// MARK: - Custom UICollectionViewCell

class ItemCell: UICollectionViewCell {
    
    static let identifier = "ItemCell"
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
