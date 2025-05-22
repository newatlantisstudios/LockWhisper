import UIKit

class NewNoteViewController: UIViewController {
    
    weak var delegate: NewNoteDelegate?
    
    // A UITextView for multi-line note entry.
    let textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1.0
        tv.layer.cornerRadius = 5.0
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Note"
        view.backgroundColor = .systemBackground
        enableKeyboardHandling()
        setupTextView()
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
    
    // When navigating back, if the text is non-empty, inform the delegate.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            let noteText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !noteText.isEmpty {
                delegate?.didAddNewNote(noteText)
            }
        }
    }
}
