import UIKit
import LocalAuthentication  // Needed for biometric authentication
import AVFoundation
// Add required imports for controllers
import CoreData

// We don't need the BiometricAuthManager stub since the real implementation exists in Other/BiometricAuthManager.swift

// We already have a real SearchViewController in the app, so we don't need a stub here

class DashboardViewController: UIViewController {
    
    // MARK: - Data
    
    let items = ["PGP", "Notepad", "Contacts", "File Vault", "Passwords", "Camera", "Voice Memo", "Media Library", "Calendar", "TODO"]
    let imageNames = ["pgp", "notepad", "contacts", "fileVault", "passwords", "camera", "voiceMemo", "mediaLibrary", "calendar", "todo"]
    
    // Favorites data
    private var favoriteItems: [FavoritesManager.FavoriteItem] = []
    
    // MARK: - UI Elements
    
    private lazy var favoritesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 90, height: 110)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(FavoriteItemCell.self, forCellWithReuseIdentifier: FavoriteItemCell.identifier)
        cv.tag = 1 // Tag to identify favorites collection view
        return cv
    }()
    
    private let favoritesLabel: UILabel = {
        let label = UILabel()
        label.text = "Quick Access"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let favoritesContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
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
        cv.tag = 2 // Tag to identify main collection view
        return cv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // .systemBackground automatically adapts to light and dark modes.
        view.backgroundColor = .systemBackground
        
        // Load favorites first so we know whether to display the favorites section
        loadFavorites()
        
        setupNavigationBar()
        setupFavoritesSection()
        setupCollectionView()
        
        // Register for favorites change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesDidChange),
            name: .favoritesDidChange,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    // Check for biometric authentication every time the view appears.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkBiometricAuthentication()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        // Add search button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(searchTapped)
        )
        
        title = "Home"
    }
    
    private func setupFavoritesSection() {
        view.addSubview(favoritesContainer)
        favoritesContainer.addSubview(favoritesLabel)
        favoritesContainer.addSubview(favoritesCollectionView)
        
        // Initially set alpha to 0 and hidden state to prevent flashing
        favoritesContainer.alpha = 0
        favoritesContainer.isHidden = true
        
        NSLayoutConstraint.activate([
            favoritesContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            favoritesContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            favoritesContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Height constraint will be handled in updateFavoritesVisibility
            
            favoritesLabel.topAnchor.constraint(equalTo: favoritesContainer.topAnchor, constant: 8),
            favoritesLabel.leadingAnchor.constraint(equalTo: favoritesContainer.leadingAnchor, constant: 16),
            
            favoritesCollectionView.topAnchor.constraint(equalTo: favoritesLabel.bottomAnchor, constant: 8),
            favoritesCollectionView.leadingAnchor.constraint(equalTo: favoritesContainer.leadingAnchor),
            favoritesCollectionView.trailingAnchor.constraint(equalTo: favoritesContainer.trailingAnchor),
            favoritesCollectionView.bottomAnchor.constraint(equalTo: favoritesContainer.bottomAnchor)
        ])
        
        // Initially set height to 0 if we don't have favorites
        let hasFavorites = !favoriteItems.isEmpty
        let heightConstraint = favoritesContainer.heightAnchor.constraint(equalToConstant: hasFavorites ? 150 : 0)
        heightConstraint.isActive = true
        
        // Update visibility based on initial state
        updateFavoritesVisibility()
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: favoritesContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        collectionView.isScrollEnabled = true
    }
    
    @objc private func favoritesDidChange() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        // Load favorites from FavoritesManager
        favoriteItems = FavoritesManager.shared.getAllFavorites()
        
        // Reload favorites collection view
        favoritesCollectionView.reloadData()
        
        // Update visibility based on whether we have favorites
        updateFavoritesVisibility()
    }
    
    private func updateFavoritesVisibility() {
        let hasFavorites = !favoriteItems.isEmpty
        
        // When no favorites, completely hide the container and set height to zero
        if hasFavorites {
            // Show favorites section
            favoritesContainer.isHidden = false
            
            // Reset height constraint to original value (150)
            NSLayoutConstraint.deactivate(favoritesContainer.constraints.filter { 
                $0.firstAttribute == .height && $0.firstItem === favoritesContainer 
            })
            
            let heightConstraint = favoritesContainer.heightAnchor.constraint(equalToConstant: 150)
            heightConstraint.isActive = true
            
            // Reset main collection view insets
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            // Show with animation
            UIView.animate(withDuration: 0.3) {
                self.favoritesContainer.alpha = 1.0
                self.view.layoutIfNeeded()
            }
        } else {
            // Completely remove the favorites section from layout
            NSLayoutConstraint.deactivate(favoritesContainer.constraints.filter { 
                $0.firstAttribute == .height && $0.firstItem === favoritesContainer 
            })
            
            // Set height to zero
            let zeroHeightConstraint = favoritesContainer.heightAnchor.constraint(equalToConstant: 0)
            zeroHeightConstraint.isActive = true
            
            // Hide with animation then set isHidden = true after animation completes
            UIView.animate(withDuration: 0.3, animations: {
                self.favoritesContainer.alpha = 0.0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.favoritesContainer.isHidden = true
            })
        }
    }
    
    // MARK: - Biometric Authentication
    
    private func checkBiometricAuthentication() {
        BiometricAuthManager.shared.authenticateIfNeeded(from: self)
    }
    
    // MARK: - Actions
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @objc private func searchTapped() {
        let searchVC = SearchViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    // MARK: - Favorites Navigation
    
    private func navigateToItemDetail(moduleType: String, itemId: String) {
        // Simple implementation that just navigates to the main module screen
        // In a real app, we would load the specific item based on itemId
        
        switch moduleType {
        case ModuleType.notes:
            let notepadVC = NotepadViewController()
            navigationController?.pushViewController(notepadVC, animated: true)
            
        case ModuleType.passwords:
            let passwordVC = PasswordViewController()
            navigationController?.pushViewController(passwordVC, animated: true)
            
        case ModuleType.calendar:
            let calendarVC = CalendarViewController()
            navigationController?.pushViewController(calendarVC, animated: true)
            
        case ModuleType.contacts:
            let contactsVC = ContactsViewController()
            navigationController?.pushViewController(contactsVC, animated: true)
            
        case ModuleType.pgp:
            let conversationsVC = ConversationsViewController()
            navigationController?.pushViewController(conversationsVC, animated: true)
            
        case ModuleType.todo:
            let todoVC = TODOViewController()
            navigationController?.pushViewController(todoVC, animated: true)
            
        case ModuleType.fileVault:
            let fileVaultVC = FileVaultViewController()
            navigationController?.pushViewController(fileVaultVC, animated: true)
            
        case ModuleType.camera:
            let cameraVC = CameraViewController()
            navigationController?.pushViewController(cameraVC, animated: true)
            
        case ModuleType.voiceMemo:
            let voiceMemoVC = VoiceMemoViewController()
            navigationController?.pushViewController(voiceMemoVC, animated: true)
            
        case ModuleType.mediaLibrary:
            let mediaLibraryVC = MediaLibraryViewController()
            navigationController?.pushViewController(mediaLibraryVC, animated: true)
            
        default:
            // Fallback to main dashboard - shouldn't happen with proper module types
            print("Unknown module type: \(moduleType)")
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension DashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 { // Favorites collection view
            return favoriteItems.count
        } else {
            return items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 1 { // Favorites collection view
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoriteItemCell.identifier, for: indexPath) as? FavoriteItemCell else {
                fatalError("Unable to dequeue FavoriteItemCell")
            }
            
            let item = favoriteItems[indexPath.item]
            cell.configure(with: item.displayName, imageName: item.iconName)
            
            return cell
            
        } else { // Main collection view
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 1 { // Favorites collection view
            let favoriteItem = favoriteItems[indexPath.item]
            navigateToItemDetail(moduleType: favoriteItem.moduleName, itemId: favoriteItem.id)
        } else { // Main collection view
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
