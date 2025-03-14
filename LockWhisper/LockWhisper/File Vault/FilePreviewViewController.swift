import UIKit
import AVKit
import UniformTypeIdentifiers

class FilePreviewViewController: UIViewController {
    
    var fileURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        previewFile()
    }
    
    private func setupNavigationBar() {
        // "Import" here means export the file to Apple Files.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importTapped))
    }
    
    @objc private func importTapped() {
        // Create a temporary decrypted file for export
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            // Decrypt the file to the temporary location
            try FileEncryptionManager.shared.decryptFile(at: fileURL, to: tempURL)
            
            // Present a document picker for exporting the decrypted file.
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
            present(documentPicker, animated: true) {
                // Schedule cleanup of the temporary file after a reasonable time
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
        } catch {
            let alert = UIAlertController(title: "Error", message: "Failed to decrypt file for export: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func previewFile() {
        guard let fileType = UTType(filenameExtension: fileURL.pathExtension) else { return }
        
        // Create a temporary file for decryption
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            // Decrypt the file to the temporary location
            try FileEncryptionManager.shared.decryptFile(at: fileURL, to: tempURL)
            
            if fileType.conforms(to: .image) {
                // Preview image using UIImageView.
                let imageView = UIImageView(frame: view.bounds)
                imageView.contentMode = .scaleAspectFit
                imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                imageView.image = UIImage(contentsOfFile: tempURL.path)
                view.addSubview(imageView)
                
                // Schedule cleanup of temporary file
                scheduleCleanup(for: tempURL)
                
            } else if fileType.conforms(to: .movie) {
                // Preview video using AVPlayerViewController.
                let player = AVPlayer(url: tempURL)
                let playerVC = AVPlayerViewController()
                playerVC.player = player
                
                // Embed AVPlayerViewController as a child.
                addChild(playerVC)
                playerVC.view.frame = view.bounds
                playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(playerVC.view)
                playerVC.didMove(toParent: self)
                
                // Start playback automatically.
                player.play()
                
                // Schedule cleanup of temporary file (longer time for videos)
                scheduleCleanup(for: tempURL, afterDelay: 300)
                
            } else {
                // For unsupported types, show a placeholder message.
                let label = UILabel(frame: view.bounds)
                label.text = "Preview not available."
                label.textAlignment = .center
                label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(label)
                
                // Cleanup immediately since we're not using the file
                scheduleCleanup(for: tempURL, afterDelay: 1)
            }
        } catch {
            // Handle decryption errors
            let label = UILabel(frame: view.bounds)
            label.text = "Failed to decrypt file: \(error.localizedDescription)"
            label.textAlignment = .center
            label.numberOfLines = 0
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(label)
        }
    }
    
    private func scheduleCleanup(for url: URL, afterDelay delay: TimeInterval = 5) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
