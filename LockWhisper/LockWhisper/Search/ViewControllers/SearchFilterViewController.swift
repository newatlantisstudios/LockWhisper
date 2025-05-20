import UIKit

protocol SearchFilterDelegate: AnyObject {
    func didUpdateFilter(_ filter: SearchFilter)
}

class SearchFilterViewController: UIViewController {
    weak var delegate: SearchFilterDelegate?
    var currentFilter = SearchFilter.all
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var selectedTypes: Set<SearchResultType> = []
    private var dateFrom: Date?
    private var dateTo: Date?
    
    private let types: [(SearchResultType, String)] = [
        (.note, "Notes"),
        (.password, "Passwords"),
        (.contact, "Contacts"),
        (.pgpMessage, "PGP Messages"),
        (.file, "Files"),
        (.todo, "To-Do Items"),
        (.voiceMemo, "Voice Memos"),
        (.event, "Calendar Events")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentFilter()
    }
    
    private func setupUI() {
        title = "Search Filters"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FilterCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadCurrentFilter() {
        selectedTypes = currentFilter.types ?? Set(types.map { $0.0 })
        dateFrom = currentFilter.dateFrom
        dateTo = currentFilter.dateTo
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        var filter = SearchFilter()
        filter.types = selectedTypes.isEmpty ? nil : selectedTypes
        filter.dateFrom = dateFrom
        filter.dateTo = dateTo
        
        delegate?.didUpdateFilter(filter)
        dismiss(animated: true)
    }
    
    @objc private func clearAllTypes() {
        selectedTypes.removeAll()
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    @objc private func selectAllTypes() {
        selectedTypes = Set(types.map { $0.0 })
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    private func showDatePicker(for row: Int) {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        
        if row == 0 {
            picker.date = dateFrom ?? Date()
        } else {
            picker.date = dateTo ?? Date()
        }
        
        let alert = UIAlertController(title: row == 0 ? "From Date" : "To Date", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50)
        ])
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            if row == 0 {
                self.dateFrom = nil
            } else {
                self.dateTo = nil
            }
            self.tableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Select", style: .default) { _ in
            if row == 0 {
                self.dateFrom = picker.date
            } else {
                self.dateTo = picker.date
            }
            self.tableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SearchFilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return types.count
        case 1: return 2
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            let (type, title) = types[indexPath.row]
            cell.textLabel?.text = title
            cell.accessoryType = selectedTypes.contains(type) ? .checkmark : .none
            
        case 1:
            if indexPath.row == 0 {
                cell.textLabel?.text = "From Date"
                if let date = dateFrom {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    cell.detailTextLabel?.text = formatter.string(from: date)
                } else {
                    cell.detailTextLabel?.text = "Any"
                }
            } else {
                cell.textLabel?.text = "To Date"
                if let date = dateTo {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    cell.detailTextLabel?.text = formatter.string(from: date)
                } else {
                    cell.detailTextLabel?.text = "Any"
                }
            }
            cell.accessoryType = .disclosureIndicator
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Filter by Type"
        case 1: return "Filter by Date"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        
        let footerView = UIView()
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear All", for: .normal)
        clearButton.addTarget(self, action: #selector(clearAllTypes), for: .touchUpInside)
        
        let selectButton = UIButton(type: .system)
        selectButton.setTitle("Select All", for: .normal)
        selectButton.addTarget(self, action: #selector(selectAllTypes), for: .touchUpInside)
        
        stackView.addArrangedSubview(clearButton)
        stackView.addArrangedSubview(selectButton)
        
        footerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -10)
        ])
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 50 : 0
    }
}

// MARK: - UITableViewDelegate

extension SearchFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let (type, _) = types[indexPath.row]
            if selectedTypes.contains(type) {
                selectedTypes.remove(type)
            } else {
                selectedTypes.insert(type)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            
        case 1:
            showDatePicker(for: indexPath.row)
            
        default:
            break
        }
    }
}