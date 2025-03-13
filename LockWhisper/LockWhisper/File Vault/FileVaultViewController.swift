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
            files = fileURLs.map { $0.lastPathComponent }
        } catch {
            print("Error loading files from disk: \(error)")
            files = []
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
                        handler: { _ in
                            let documentPicker = UIDocumentPickerViewController(
                                forExporting: [fileURL], asCopy: true)
                            self.present(
                                documentPicker, animated: true, completion: nil)
                        }))
                alert.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                )
                present(alert, animated: true, completion: nil)
            }
        }
    }
}
