import UIKit

protocol AddEventDelegate: AnyObject {
    func didAddEvent()
}

class AddEventViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    private var selectedDate: Date
    private var startDate: Date
    private var endDate: Date
    private var selectedColor: String = "#007AFF" // Default blue color
    
    private let calendarManager = CalendarManager.shared
    
    weak var delegate: AddEventDelegate?
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Event Title"
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .done
        return textField
    }()
    
    private let locationTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Location (optional)"
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .done
        return textField
    }()
    
    private let notesTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        return textView
    }()
    
    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .inline
        return picker
    }()
    
    private let endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .inline
        return picker
    }()
    
    private let colorSegmentedControl: UISegmentedControl = {
        let colors = ["Blue", "Red", "Green", "Purple", "Orange"]
        let control = UISegmentedControl(items: colors)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0 // Blue is default
        return control
    }()
    
    private let startDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Start"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let endDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "End"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let notesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Notes"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Color"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    // MARK: - Initialization
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        
        // Set default start and end times
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let startOfDay = calendar.date(from: components)!
        
        let startComponents = DateComponents(hour: 9, minute: 0) // 9:00 AM
        self.startDate = calendar.date(byAdding: startComponents, to: startOfDay)!
        
        let endComponents = DateComponents(hour: 10, minute: 0) // 10:00 AM
        self.endDate = calendar.date(byAdding: endComponents, to: startOfDay)!
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Event"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        setupUI()
        setupDatePickers()
        setupColorControl()
        
        // Set up text field delegates
        titleTextField.delegate = self
        locationTextField.delegate = self
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleTextField)
        contentView.addSubview(locationTextField)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorSegmentedControl)
        contentView.addSubview(startDateLabel)
        contentView.addSubview(startDatePicker)
        contentView.addSubview(endDateLabel)
        contentView.addSubview(endDatePicker)
        contentView.addSubview(notesLabel)
        contentView.addSubview(notesTextView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            locationTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 15),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            colorLabel.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 15),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            colorSegmentedControl.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 8),
            colorSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            colorSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            startDateLabel.topAnchor.constraint(equalTo: colorSegmentedControl.bottomAnchor, constant: 20),
            startDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            startDatePicker.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 10),
            startDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            endDateLabel.topAnchor.constraint(equalTo: startDatePicker.bottomAnchor, constant: 20),
            endDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            endDatePicker.topAnchor.constraint(equalTo: endDateLabel.bottomAnchor, constant: 10),
            endDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            endDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            notesLabel.topAnchor.constraint(equalTo: endDatePicker.bottomAnchor, constant: 20),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 10),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupDatePickers() {
        startDatePicker.date = startDate
        endDatePicker.date = endDate
        
        startDatePicker.addTarget(self, action: #selector(startDateChanged(_:)), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(endDateChanged(_:)), for: .valueChanged)
    }
    
    private func setupColorControl() {
        colorSegmentedControl.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func startDateChanged(_ sender: UIDatePicker) {
        startDate = sender.date
        
        // If end date is before start date, update it
        if endDate < startDate {
            endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
            endDatePicker.date = endDate
        }
    }
    
    @objc private func endDateChanged(_ sender: UIDatePicker) {
        endDate = sender.date
        
        // If end date is before start date, update start date
        if endDate < startDate {
            startDate = Calendar.current.date(byAdding: .hour, value: -1, to: endDate)!
            startDatePicker.date = startDate
        }
    }
    
    @objc private func colorChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedColor = "#007AFF" // Blue
        case 1:
            selectedColor = "#FF3B30" // Red
        case 2:
            selectedColor = "#34C759" // Green
        case 3:
            selectedColor = "#AF52DE" // Purple
        case 4:
            selectedColor = "#FF9500" // Orange
        default:
            selectedColor = "#007AFF" // Default blue
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter an event title")
            return
        }
        
        let event = CalendarEvent(
            title: title,
            location: locationTextField.text,
            notes: notesTextView.text,
            startDate: startDate,
            endDate: endDate,
            color: selectedColor
        )
        
        calendarManager.addEvent(event)
        delegate?.didAddEvent()
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
