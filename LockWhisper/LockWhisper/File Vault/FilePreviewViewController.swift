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
        // Present a document picker for exporting the file.
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        present(documentPicker, animated: true, completion: nil)
    }
    
    private func previewFile() {
        guard let fileType = UTType(filenameExtension: fileURL.pathExtension) else { return }
        
        if fileType.conforms(to: .image) {
            // Preview image using UIImageView.
            let imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFit
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.image = UIImage(contentsOfFile: fileURL.path)
            view.addSubview(imageView)
            
        } else if fileType.conforms(to: .movie) {
            // Preview video using AVPlayerViewController.
            let player = AVPlayer(url: fileURL)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            
            // Embed AVPlayerViewController as a child.
            addChild(playerVC)
            playerVC.view.frame = view.bounds
            playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
            
            // Optionally start playback automatically.
            player.play()
        } else {
            // For unsupported types, show a placeholder message.
            let label = UILabel(frame: view.bounds)
            label.text = "Preview not available."
            label.textAlignment = .center
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(label)
        }
    }
}
