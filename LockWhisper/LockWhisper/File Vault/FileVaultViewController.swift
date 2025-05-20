import UIKit
import UniformTypeIdentifiers

class FileVaultViewController: UIViewController {

    // Data source for file titles loaded from disk.
    var files: [String] = []

    // Table view to display file titles.
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "File Vault"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupTableView()
    }

    // Reload files from disk every time the view appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFilesFromDocumentsDirectory()
        tableView.reloadData()
        
        // Index files for search
        indexFiles()
    }

    // MARK: - Setup Methods

    private func setupNavigationBar() {
        // Plus button to add files.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addFile)
        )
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UITableViewCell.self, forCellReuseIdentifier: "FileCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func addFile() {
        let fileSelectionVC = FileSelectionViewController()
        fileSelectionVC.modalPresentationStyle = .fullScreen
        fileSelectionVC.didSelectFile = { [weak self] selectedFileURL in
            self?.dismiss(
                animated: true,
                completion: {
                    let initialTitle = selectedFileURL.lastPathComponent
                    self?.presentFileAddViewController(
                        with: initialTitle, fileURL: selectedFileURL)
                })
        }
        present(fileSelectionVC, animated: true, completion: nil)
    }

    private func presentFileAddViewController(
        with initialTitle: String, fileURL: URL
    ) {
        let fileAddVC = FileAddViewController()
        fileAddVC.initialFileName = initialTitle
        fileAddVC.fileURL = fileURL
        fileAddVC.onFileAdded = { [weak self] newFileTitle in
            self?.dismiss(
                animated: true,
                completion: {
                    // Reload the file list from disk and update the table view immediately.
                    self?.loadFilesFromDocumentsDirectory()
                    self?.tableView.reloadData()
                })
        }
        let navController = UINavigationController(
            rootViewController: fileAddVC)
        present(navController, animated: true, completion: nil)
    }

    // MARK: - File Loading Method

    private func loadFilesFromDocumentsDirectory() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsURL, includingPropertiesForKeys: nil)
            
            // Check for unencrypted files and encrypt them (migration)
            migrateUnencryptedFiles(fileURLs)
            
            // Update the list of files
            files = fileURLs.map { $0.lastPathComponent }
        } catch {
            print("Error loading files from disk: \(error)")
            files = []
        }
    }
    
    private func migrateUnencryptedFiles(_ fileURLs: [URL]) {
        for fileURL in fileURLs {
            // Skip files that are too small to check
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  let fileSize = attributes[.size] as? UInt64,
                  fileSize > 0 else {
                continue
            }
            
            // Read first few bytes to check if encrypted
            let handler = try? FileHandle(forReadingFrom: fileURL)
            let headerData = handler?.readData(ofLength: 4)
            handler?.closeFile()
            
            if let data = headerData, !FileEncryptionManager.shared.isEncryptedData(data) {
                print("Migrating unencrypted file: \(fileURL.lastPathComponent)")
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                
                do {
                    // Create an encrypted version
                    try FileEncryptionManager.shared.encryptFile(at: fileURL, to: tempURL)
                    
                    // Replace the original file
                    try FileManager.default.removeItem(at: fileURL)
                    try FileManager.default.moveItem(at: tempURL, to: fileURL)
                    
                    print("Successfully migrated file: \(fileURL.lastPathComponent)")
                } catch {
                    print("Failed to migrate file \(fileURL.lastPathComponent): \(error)")
                    // Clean up the temp file if it exists
                    try? FileManager.default.removeItem(at: tempURL)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension FileVaultViewController: UITableViewDataSource, UITableViewDelegate {

    // Number of rows equals the number of files.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return files.count
    }

    // Configure the cell with the file title.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FileCell", for: indexPath)
        cell.textLabel?.text = files[indexPath.row]
        return cell
    }

    // Allow swipe-to-delete.
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let fileName = files[indexPath.row]
            let fileManager = FileManager.default
            guard
                let documentsURL = fileManager.urls(
                    for: .documentDirectory, in: .userDomainMask
                ).first
            else { return }
            let fileURL = documentsURL.appendingPathComponent(fileName)

            do {
                // Remove file from disk.
                try fileManager.removeItem(at: fileURL)
                // Update the local data source.
                files.remove(at: indexPath.row)
                // Remove the row from the table view.
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                print("Error deleting file: \(error)")
            }
        }
    }

    // When a file is tapped, check its type and act accordingly.
    func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        let fileName = files[indexPath.row]
        let fileManager = FileManager.default
        guard
            let documentsURL = fileManager.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else { return }
        let fileURL = documentsURL.appendingPathComponent(fileName)

        // Determine file type using UTType.
        if let fileType = UTType(filenameExtension: fileURL.pathExtension) {
            if fileType.conforms(to: .image) || fileType.conforms(to: .movie) {
                // If it's an image or video, push the preview view controller.
                let previewVC = FilePreviewViewController()
                previewVC.fileURL = fileURL
                previewVC.title = fileName
                navigationController?.pushViewController(
                    previewVC, animated: true)
            } else {
                // For non-image/video files, present an option to export to Apple Files.
                let alert = UIAlertController(
                    title: "Export File",
                    message:
                        "Would you like to export this file to the Apple Files app?",
                    preferredStyle: .actionSheet)
                alert.addAction(
                    UIAlertAction(
                        title: "Export", style: .default,
                        handler: { [weak self] _ in
                            // Create a temporary decrypted file for export
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                            
                            do {
                                // Decrypt the file to the temporary location
                                try FileEncryptionManager.shared.decryptFile(at: fileURL, to: tempURL)
                                
                                // Present a document picker for exporting the decrypted file
                                let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
                                self?.present(documentPicker, animated: true) {
                                    // Schedule cleanup of the temporary file after a reasonable time
                                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
                                        try? FileManager.default.removeItem(at: tempURL)
                                    }
                                }
                            } catch {
                                let errorAlert = UIAlertController(
                                    title: "Error",
                                    message: "Failed to decrypt file for export: \(error.localizedDescription)",
                                    preferredStyle: .alert
                                )
                                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                                self?.present(errorAlert, animated: true)
                            }
                        }))
                alert.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                )
                
                // For iPad compatibility
                if let popoverController = alert.popoverPresentationController {
                    popoverController.sourceView = tableView.cellForRow(at: indexPath)
                    popoverController.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? CGRect.zero
                }
                
                present(alert, animated: true, completion: nil)
            }
        }
    }
}
