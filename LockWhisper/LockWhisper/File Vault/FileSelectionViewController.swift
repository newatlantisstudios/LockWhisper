import UIKit
import UniformTypeIdentifiers

class FileSelectionViewController: UIViewController, UIDocumentPickerDelegate {
    
    // Closure to pass the selected file URL.
    var didSelectFile: ((URL) -> Void)?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentDocumentPicker()
    }
    
    private func presentDocumentPicker() {
        // Configure the document picker to allow any file type.
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: - UIDocumentPickerDelegate Methods
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else {
            dismiss(animated: true, completion: nil)
            return
        }
        // Pass the selected file URL back.
        didSelectFile?(selectedURL)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
}
