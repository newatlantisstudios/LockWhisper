import UIKit
import AVKit

class MediaLibraryViewController: UIViewController {
    
    // MARK: - Properties
    
    var mediaFiles = [MediaFile]()
    private let mediaManager = MediaManager.shared
    
    struct MediaFile {
        let url: URL
        let isVideo: Bool
        let isVoiceMemo: Bool
        let creationDate: Date
        private let mediaManager = MediaManager.shared
        
        var thumbnail: UIImage {
            if isVideo {
                return mediaManager.generateVideoThumbnail(from: url) ?? UIImage(systemName: "video")!
            } else if isVoiceMemo {
                return UIImage(systemName: "waveform")!.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            } else {
                if url.pathExtension.lowercased() == "enc" {
                    return mediaManager.loadImage(from: url) ?? UIImage(systemName: "photo")!
                } else {
                    return UIImage(contentsOfFile: url.path) ?? UIImage(systemName: "photo")!
                }
            }
        }
    }
    
    // MARK: - UI Elements
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let screenWidth = UIScreen.main.bounds.width
        let itemSize = (screenWidth - 3) / 3 // 3 items per row with 1pt spacing
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        return cv
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No media files available"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 18)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Media Library"
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMediaFiles()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadMediaFiles() {
        // Get app document directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Path to the MediaLibrary folder
        let mediaDirectory = documentsDirectory.appendingPathComponent("MediaLibrary")
        
        // Check if directory exists
        if !FileManager.default.fileExists(atPath: mediaDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating media directory: \(error)")
                updateEmptyState(true)
                return
            }
        }
        
        do {
            // Get all files in the directory
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: mediaDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            // Process files
            mediaFiles = fileURLs.compactMap { url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.creationDateKey])
                    let creationDate = resourceValues.creationDate ?? Date()
                    
                    // For encrypted files, we need to determine type by other means
                    let isVideo: Bool
                    if url.pathExtension.lowercased() == "enc" {
                        // For encrypted files, we can use filename metadata or check file contents
                        // Here we're using a simple approach based on the MediaManager
                        isVideo = mediaManager.isVideo(url: url)
                    } else {
                        isVideo = url.pathExtension.lowercased() == "mov"
                    }
                    
                    // Check if it's a voice memo
                    let isVoiceMemo = mediaManager.isVoiceMemo(url: url)
                    
                    return MediaFile(url: url, isVideo: isVideo, isVoiceMemo: isVoiceMemo, creationDate: creationDate)
                } catch {
                    print("Error getting file attributes: \(error)")
                    return nil
                }
            }
            
            // Sort by creation date (newest first)
            mediaFiles.sort { $0.creationDate > $1.creationDate }
            
            // Update UI
            DispatchQueue.main.async {
                self.updateEmptyState(self.mediaFiles.isEmpty)
                self.collectionView.reloadData()
                
                // Index voice memos for search
                self.indexVoiceMemos()
            }
        } catch {
            print("Error loading media files: \(error)")
            updateEmptyState(true)
        }
    }
    
    private func updateEmptyState(_ isEmpty: Bool) {
        emptyStateLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
    
    // MARK: - Media Handling
    
    private func playVoiceMemo(at url: URL) {
        // Show the voice memo player
        let voiceMemoPlayerVC = VoiceMemoPlayerViewController()
        voiceMemoPlayerVC.memoURL = url
        navigationController?.pushViewController(voiceMemoPlayerVC, animated: true)
    }
    
    private func viewImage(_ image: UIImage) {
        // The image is already decrypted at this point (in the thumbnail property)
        let imageVC = ImageViewerController(image: image)
        imageVC.modalPresentationStyle = .fullScreen
        present(imageVC, animated: true)
    }
    
    // Image Viewer Controller
    class ImageViewerController: UIViewController {
        
        private let displayedImage: UIImage
        
        init(image: UIImage) {
            self.displayedImage = image
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            setupImageView()
            setupCloseButton()
        }
        
        private func setupImageView() {
            let imageView = UIImageView(image: displayedImage)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        private func setupCloseButton() {
            let closeButton = UIButton(type: .system)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.setTitle("Close", for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
            
            view.addSubview(closeButton)
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
        
        @objc private func closeButtonTapped() {
            dismiss(animated: true)
        }
    }
    
    private func playVideo(at url: URL) {
        // For encrypted videos, we need to decrypt to a temporary file first
        if url.pathExtension.lowercased() == "enc" {
            mediaManager.loadVideoForPlayback(from: url) { [weak self] tempURL in
                guard let self = self, let tempURL = tempURL else {
                    self?.showAlert(title: "Error", message: "Could not prepare video for playback")
                    return
                }
                
                let player = AVPlayer(url: tempURL)
                let playerVC = AVPlayerViewController()
                playerVC.player = player
                
                self.present(playerVC, animated: true) {
                    player.play()
                }
            }
        } else {
            // Non-encrypted video (legacy support)
            let player = AVPlayer(url: url)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            
            present(playerVC, animated: true) {
                player.play()
            }
        }
    }
    
    // MARK: - Media Deletion
    
    private func deleteMedia(at indexPath: IndexPath) {
        let mediaFile = mediaFiles[indexPath.item]
        
        do {
            try FileManager.default.removeItem(at: mediaFile.url)
            mediaFiles.remove(at: indexPath.item)
            
            collectionView.deleteItems(at: [indexPath])
            updateEmptyState(mediaFiles.isEmpty)
        } catch {
            print("Error deleting file: \(error)")
            showAlert(title: "Error", message: "Failed to delete the file")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Item", message: "Are you sure you want to delete this item?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteMedia(at: indexPath)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension MediaLibraryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else {
            fatalError("Unable to dequeue MediaCell")
        }
        
        let mediaFile = mediaFiles[indexPath.item]
        cell.configure(with: mediaFile.thumbnail, isVideo: mediaFile.isVideo)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let mediaFile = mediaFiles[indexPath.item]
        
        if mediaFile.isVideo {
            playVideo(at: mediaFile.url)
        } else if mediaFile.isVoiceMemo {
            playVoiceMemo(at: mediaFile.url)
        } else if mediaFile.url.pathExtension.lowercased() == "enc" {
            // For encrypted images
            if let image = mediaManager.loadImage(from: mediaFile.url) {
                viewImage(image)
            }
        } else if let image = UIImage(contentsOfFile: mediaFile.url.path) {
            // For non-encrypted images (legacy support)
            viewImage(image)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.showDeleteConfirmation(for: indexPath)
            }
            
            return UIMenu(title: "", children: [deleteAction])
        }
    }
}

// MARK: - MediaCell

class MediaCell: UICollectionViewCell {
    
    static let identifier = "MediaCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let videoIndicator: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "video.fill"))
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        contentView.addSubview(videoIndicator)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            videoIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            videoIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            videoIndicator.widthAnchor.constraint(equalToConstant: 24),
            videoIndicator.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        videoIndicator.isHidden = true
    }
    
    // MARK: - Configuration
    
    func configure(with image: UIImage, isVideo: Bool) {
        imageView.image = image
        videoIndicator.isHidden = !isVideo
    }
}
