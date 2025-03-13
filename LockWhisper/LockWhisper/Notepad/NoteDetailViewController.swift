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
        textView.text = note.text
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
            if updatedText != note.text {
                delegate?.didUpdateNote(updatedText, at: noteIndex)
            }
        }
    }
}
