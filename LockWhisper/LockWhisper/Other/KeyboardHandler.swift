import UIKit

class KeyboardHandler {
    private weak var viewController: UIViewController?
    private var keyboardHeight: CGFloat = 0
    private var originalViewFrame: CGRect = .zero
    private var isKeyboardVisible = false
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        self.originalViewFrame = viewController.view.frame
        setupKeyboardNotifications()
    }
    
    deinit {
        removeKeyboardNotifications()
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let viewController = viewController else { return }
        
        keyboardHeight = keyboardFrame.cgRectValue.height
        
        if !isKeyboardVisible {
            isKeyboardVisible = true
            adjustViewForKeyboard(show: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        if isKeyboardVisible {
            isKeyboardVisible = false
            adjustViewForKeyboard(show: false)
        }
    }
    
    private func adjustViewForKeyboard(show: Bool) {
        guard let viewController = viewController else { return }
        
        if let scrollView = findScrollView(in: viewController.view) {
            adjustScrollView(scrollView, show: show)
        } else {
            adjustViewFrame(show: show)
        }
    }
    
    private func findScrollView(in view: UIView) -> UIScrollView? {
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                return scrollView
            }
            if let foundScrollView = findScrollView(in: subview) {
                return foundScrollView
            }
        }
        return nil
    }
    
    private func adjustScrollView(_ scrollView: UIScrollView, show: Bool) {
        if show {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            if let activeField = findFirstResponder(in: scrollView) {
                scrollToVisibleField(scrollView: scrollView, field: activeField)
            }
        } else {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }
    }
    
    private func adjustViewFrame(show: Bool) {
        guard let viewController = viewController else { return }
        
        UIView.animate(withDuration: 0.3) {
            if show {
                let newHeight = self.originalViewFrame.height - self.keyboardHeight
                viewController.view.frame = CGRect(
                    x: self.originalViewFrame.origin.x,
                    y: self.originalViewFrame.origin.y,
                    width: self.originalViewFrame.width,
                    height: newHeight
                )
            } else {
                viewController.view.frame = self.originalViewFrame
            }
        }
    }
    
    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        
        for subview in view.subviews {
            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }
    
    private func scrollToVisibleField(scrollView: UIScrollView, field: UIView) {
        let fieldFrame = field.convert(field.bounds, to: scrollView)
        let visibleRect = CGRect(
            x: fieldFrame.origin.x,
            y: fieldFrame.origin.y,
            width: fieldFrame.width,
            height: fieldFrame.height + 20
        )
        scrollView.scrollRectToVisible(visibleRect, animated: true)
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var keyboardHandler = "keyboardHandler"
    }
    
    var keyboardHandler: KeyboardHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.keyboardHandler) as? KeyboardHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.keyboardHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func enableKeyboardHandling() {
        keyboardHandler = KeyboardHandler(viewController: self)
    }
    
    func disableKeyboardHandling() {
        keyboardHandler = nil
    }
}