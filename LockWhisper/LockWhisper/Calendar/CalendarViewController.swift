import UIKit

class CalendarViewController: UIViewController {
    
    // MARK: - Properties
    private let calendarManager = CalendarManager.shared
    private var events: [CalendarEvent] = []
    private var selectedDate = Date()
    
    // MARK: - UI Elements
    private lazy var calendarView: UICalendarView = {
        let calendarView = UICalendarView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.calendar = .current
        calendarView.delegate = self
        calendarView.fontDesign = .rounded
        
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = dateSelection
        
        return calendarView
    }()
    
    private lazy var eventsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(EventCell.self, forCellReuseIdentifier: EventCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        return tableView
    }()
    
    private lazy var addEventButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(addEventTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Calendar"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Index calendar events for search
        indexCalendarEvents()
        fetchEvents(for: selectedDate)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(calendarView)
        view.addSubview(eventsTableView)
        view.addSubview(addEventButton)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: 300),
            
            eventsTableView.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
            eventsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            eventsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            eventsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            addEventButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addEventButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addEventButton.widthAnchor.constraint(equalToConstant: 50),
            addEventButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Event Handling
    private func fetchEvents(for date: Date) {
        events = calendarManager.getEvents(for: date)
        eventsTableView.reloadData()
    }
    
    @objc private func addEventTapped() {
        let addEventVC = AddEventViewController(selectedDate: selectedDate)
        addEventVC.delegate = self
        let navController = UINavigationController(rootViewController: addEventVC)
        present(navController, animated: true)
    }
}

// MARK: - UICalendarViewDelegate
extension CalendarViewController: UICalendarViewDelegate {
    
}

// MARK: - UICalendarSelectionSingleDateDelegate
extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else {
            return
        }
        
        selectedDate = date
        fetchEvents(for: date)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension CalendarViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if events.isEmpty {
            return 1 // Show "No events" cell
        }
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventCell.identifier, for: indexPath) as? EventCell else {
            return UITableViewCell()
        }
        
        if events.isEmpty {
            cell.configure(with: nil)
            return cell
        }
        
        let event = events[indexPath.row]
        cell.configure(with: event)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if events.isEmpty {
            return
        }
        
        let event = events[indexPath.row]
        let eventDetailVC = EventDetailViewController(event: event)
        eventDetailVC.delegate = self
        navigationController?.pushViewController(eventDetailVC, animated: true)
    }
}

// MARK: - AddEventDelegate
extension CalendarViewController: AddEventDelegate {
    func didAddEvent() {
        fetchEvents(for: selectedDate)
    }
}

// MARK: - EventDetailDelegate
extension CalendarViewController: EventDetailDelegate {
    func didUpdateEvent() {
        fetchEvents(for: selectedDate)
    }
    
    func didDeleteEvent() {
        fetchEvents(for: selectedDate)
    }
}
