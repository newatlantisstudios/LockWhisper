import UIKit

class StyledButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
        
        // Default system blue gradient
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.9).cgColor,
            UIColor.systemBlue.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        layer.insertSublayer(gradientLayer, at: 0)
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        // Set content insets
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func setStyle(_ style: ButtonStyle) {
        switch style {
        case .primary:
            gradientLayer.colors = [
                UIColor.systemBlue.withAlphaComponent(0.9).cgColor,
                UIColor.systemBlue.cgColor
            ]
        case .secondary:
            gradientLayer.colors = [
                UIColor.systemGray4.cgColor,
                UIColor.systemGray3.cgColor
            ]
        case .warning:
            gradientLayer.colors = [
                UIColor.systemOrange.withAlphaComponent(0.9).cgColor,
                UIColor.systemOrange.cgColor
            ]
        case .destructive:
            gradientLayer.colors = [
                UIColor.systemRed.withAlphaComponent(0.9).cgColor,
                UIColor.systemRed.cgColor
            ]
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ?
                    CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.alpha = self.isHighlighted ? 0.9 : 1.0
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
        }
    }
}

enum ButtonStyle {
    case primary
    case secondary
    case warning
    case destructive
}
