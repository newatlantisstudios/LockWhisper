import UIKit

class FileAddViewController: UIViewController {
    
    // The URL of the file selected from the Apple Files app.
    var fileURL: URL?
    
    // Initial file name passed from the file selection.
    var initialFileName: String?
    
    // Closure to pass back the final file title.
    var onFileAdded: ((String) -> Void)?
    
    // Editable text field for the file title.
    let fileTitleTextField: UITextField = {
         let tf = UITextField()
         tf.translatesAutoresizingMaskIntoConstraints = false
         tf.placeholder = "Enter file title"
         tf.borderStyle = .roundedRect
         return tf
    }()
    
    override func viewDidLoad() {
         super.viewDidLoad()
         title = "Add File"
         view.backgroundColor = .systemBackground
         setupNavigationBar()
         setupViews()
         fileTitleTextField.text = initialFileName
    }
    
    private func setupNavigationBar() {
         navigationItem.leftBarButtonItem = UIBarButtonItem(
              barButtonSystemItem: .cancel,
              target: self,
              action: #selector(cancelTapped)
         )
    }
    
    private func setupViews() {
         view.addSubview(fileTitleTextField)
         let addFileButton = UIButton(type: .system)
         addFileButton.translatesAutoresizingMaskIntoConstraints = false
         addFileButton.setTitle("Add File to Vault", for: .normal)
         addFileButton.addTarget(self, action: #selector(addFileTapped), for: .touchUpInside)
         view.addSubview(addFileButton)
         
         NSLayoutConstraint.activate([
              fileTitleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
              fileTitleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
              fileTitleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
              fileTitleTextField.heightAnchor.constraint(equalToConstant: 40),
              
              addFileButton.topAnchor.constraint(equalTo: fileTitleTextField.bottomAnchor, constant: 20),
              addFileButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
         ])
    }
    
    @objc private func addFileTapped() {
         guard let fileTitle = fileTitleTextField.text, !fileTitle.isEmpty else {
             let alert = UIAlertController(title: "Error", message: "File title cannot be empty.", preferredStyle: .alert)
             alert.addAction(UIAlertAction(title: "OK", style: .default))
             present(alert, animated: true)
             return
         }
         
         // Save (copy) and encrypt the file locally.
         if let sourceURL = self.fileURL {
             let fileManager = FileManager.default
             let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
             // Use the new file title as the destination file name.
             let destinationURL = documentsDirectory.appendingPathComponent(fileTitle)
             
             do {
                 // Remove an existing file at the destination if needed.
                 if fileManager.fileExists(atPath: destinationURL.path) {
                     try fileManager.removeItem(at: destinationURL)
                 }
                 
                 // Encrypt and save the file
                 try FileEncryptionManager.shared.encryptFile(at: sourceURL, to: destinationURL)
             } catch {
                 let alert = UIAlertController(title: "Error", message: "Failed to save file: \(error.localizedDescription)", preferredStyle: .alert)
                 alert.addAction(UIAlertAction(title: "OK", style: .default))
                 present(alert, animated: true)
                 return
             }
         }
         // Notify that the file has been added.
         onFileAdded?(fileTitle)
    }
    
    @objc private func cancelTapped() {
         dismiss(animated: true, completion: nil)
    }
}
