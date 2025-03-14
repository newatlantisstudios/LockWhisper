import UIKit

class NoteDetailViewController: UIViewController {
    
    weak var delegate: NoteDetailDelegate?
    
    // The Note object and its index in the array.
    var note: Note
    var noteIndex: Int
    
    // A UITextView for editing.
    let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1.0
        tv.layer.cornerRadius = 5.0
        return tv
    }()
    
    init(note: Note, index: Int) {
        self.note = note
        self.noteIndex = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Note"
        view.backgroundColor = .systemBackground
        setupTextView()
        
        let storedText = note.text ?? ""
        
        // Try to decrypt the text if it's encrypted
        if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
            do {
                let decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                textView.text = decryptedText
            } catch {
                // Fallback to the stored text if decryption fails
                textView.text = storedText
                print("Failed to decrypt note: \(error)")
            }
        } else {
            // Use the plain text for unencrypted notes
            textView.text = storedText
        }
    }
    
    private func setupTextView() {
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // When navigating back, update the note if the text changed.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            let updatedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Get the original text (decrypted)
            let originalDecryptedText: String
            let storedText = note.text ?? ""
            
            if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
                do {
                    originalDecryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                } catch {
                    originalDecryptedText = storedText
                }
            } else {
                originalDecryptedText = storedText
            }
            
            // Only call delegate if the text actually changed
            if updatedText != originalDecryptedText {
                delegate?.didUpdateNote(updatedText, at: noteIndex)
            }
        }
    }
    
}

// MARK: - Encryption Extensions for NoteDetailViewController

extension NoteDetailViewController {
    // Decrypt and load note text
    func loadDecryptedNoteText() {
        let storedText = note.text ?? ""
        
        // Try to decrypt the text if it's encrypted
        if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
            do {
                let decryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
                textView.text = decryptedText
            } catch {
                // Fallback to the stored text if decryption fails
                textView.text = storedText
                print("Failed to decrypt note: \(error)")
            }
        } else {
            // Use the plain text for unencrypted notes
            textView.text = storedText
        }
    }
    
    // Modified viewWillDisappear to compare decrypted text properly
    func handleTextChange() {
        let updatedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get the original text (decrypted)
        let originalDecryptedText: String
        let storedText = note.text ?? ""
        
        if NoteEncryptionManager.shared.isEncryptedBase64String(storedText) {
            do {
                originalDecryptedText = try NoteEncryptionManager.shared.decryptBase64ToString(storedText)
            } catch {
                originalDecryptedText = storedText
            }
        } else {
            originalDecryptedText = storedText
        }
        
        // Only call delegate if the text actually changed
        if updatedText != originalDecryptedText {
            delegate?.didUpdateNote(updatedText, at: noteIndex)
        }
    }
}
