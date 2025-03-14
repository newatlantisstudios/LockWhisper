import UIKit

class NotesViewController: UIViewController {
    private var contact: ContactPGP
    private let textView = UITextView()

    // Initialize with the conversation's contact so the notes remain unique.
    init(contact: ContactPGP) {
        self.contact = contact
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes for \(contact.name)"

        setupUI()
        // Load existing notes with decryption
        textView.text = loadEncryptedNote()
    }

    // Save note with encryption
    private func saveEncryptedNote(_ noteText: String) {
        do {
            // Encrypt the note text
            let encryptedNote = try PGPEncryptionManager.shared
                .encryptStringToBase64(noteText)

            // Update the contact's notes
            contact.notes = encryptedNote

            // Update contacts in UserDefaults
            var contacts = UserDefaults.standard.contacts
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
                UserDefaults.standard.contacts = contacts
            }
        } catch {
            print("Failed to encrypt note: \(error.localizedDescription)")

            // Fallback to saving unencrypted
            contact.notes = noteText
            var contacts = UserDefaults.standard.contacts
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
                UserDefaults.standard.contacts = contacts
            }
        }
    }

    // Load note with decryption
    private func loadEncryptedNote() -> String {
        guard let note = contact.notes else { return "" }

        if PGPEncryptionManager.shared.isEncryptedBase64String(note) {
            do {
                // Decrypt the note
                return try PGPEncryptionManager.shared.decryptBase64ToString(
                    note)
            } catch {
                print("Failed to decrypt note: \(error.localizedDescription)")
                return note  // Return as is if decryption fails
            }
        } else {
            return note  // Return unencrypted note
        }
    }

    private func setupUI() {
        // Use dynamic system colors for backgrounds and labels.
        view.backgroundColor = .systemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    // This ensures any unsaved changes are committed and stored.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            let noteText = textView.text.trimmingCharacters(
                in: .whitespacesAndNewlines)
            if !noteText.isEmpty {
                saveEncryptedNote(noteText)
            }
        }
    }

    // If the user changes appearance (e.g., from light to dark) while this view is active:
    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Check if the appearance changed (light <-> dark).
        if traitCollection.hasDifferentColorAppearance(
            comparedTo: previousTraitCollection)
        {
            updateColors()
        }
    }

    // Update dynamic colors if needed.
    private func updateColors() {
        view.backgroundColor = .systemBackground
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
    }
}
