import UIKit

class EventCell: UITableViewCell {
    
    static let identifier = "EventCell"
    
    // MARK: - UI Elements
    private let colorIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(colorIndicatorView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            colorIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            colorIndicatorView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: colorIndicatorView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            locationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with event: CalendarEvent?) {
        if let event = event {
            titleLabel.text = event.title
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
                timeLabel.text = "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
            } else {
                formatter.dateStyle = .short
                timeLabel.text = "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
            }
            
            locationLabel.text = event.location?.isEmpty == false ? event.location : "No location"
            colorIndicatorView.backgroundColor = hexStringToUIColor(hex: event.color)
            colorIndicatorView.isHidden = false
        } else {
            // No events case
            titleLabel.text = "No events for this day"
            timeLabel.text = ""
            locationLabel.text = ""
            colorIndicatorView.isHidden = true
        }
    }
    
    // Helper function to convert hex color string to UIColor
    private func hexStringToUIColor(hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
