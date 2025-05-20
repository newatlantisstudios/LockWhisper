import UIKit
import Foundation
import CoreData

class SearchViewController: UIViewController {
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView()
    private let filterButton = UIButton(type: .system)
    
    private var searchResults: [SearchResult] = []
    private var recentSearches: [String] = []
    private var currentFilter = SearchFilter.all
    private var isShowingRecentSearches = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecentSearches()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Automatically activate the search bar when view appears
        searchController.searchBar.becomeFirstResponder()
    }
    
    private func setupUI() {
        title = "Search"
        view.backgroundColor = .systemBackground
        
        // Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search all items..."
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        // Filter Button
        filterButton.setTitle("Filters", for: .normal)
        filterButton.addTarget(self, action: #selector(showFilters), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: filterButton)
        
        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecentSearchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadRecentSearches() {
        recentSearches = SearchIndexManager.shared.getRecentSearches()
        tableView.reloadData()
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            isShowingRecentSearches = true
            loadRecentSearches()
            return
        }
        
        isShowingRecentSearches = false
        SearchIndexManager.shared.addRecentSearch(query)
        searchResults = SearchIndexManager.shared.search(query: query, filter: currentFilter)
        tableView.reloadData()
    }
    
    @objc private func showFilters() {
        let filterVC = SearchFilterViewController()
        filterVC.currentFilter = currentFilter
        filterVC.delegate = self
        let nav = UINavigationController(rootViewController: filterVC)
        present(nav, animated: true)
    }
    
    private func navigateToResult(_ result: SearchResult) {
        switch result.type {
        case .note:
            navigateToNote(with: result.id)
        case .password:
            navigateToPassword(with: result.id)
        case .contact:
            navigateToContact(with: result.id)
        case .pgpMessage:
            navigateToPGPMessage(with: result.id)
        case .file:
            navigateToFile(with: result.id)
        case .todo:
            navigateToTodo(with: result.id)
        case .voiceMemo:
            navigateToVoiceMemo(with: result.id)
        case .event:
            navigateToEvent(with: result.id)
        }
    }
    
    // MARK: - Navigation Methods
    
    // Helper function to convert URL string to NSManagedObjectID
    private func objectID(from urlString: String) -> NSManagedObjectID? {
        guard let url = URL(string: urlString) else { return nil }
        
        let coordinator = CoreDataManager.shared.persistentContainer.persistentStoreCoordinator
        return coordinator.managedObjectID(forURIRepresentation: url)
    }
    
    private func navigateToNote(with id: String) {
        // CoreData ID: Convert to ObjectID and fetch the note
        if let objectID = objectID(from: id) {
            if let note = try? CoreDataManager.shared.context.existingObject(with: objectID) as? Note {
                // Find the proper index in NotepadViewController's notes array
                // Using 0 as a fallback index if we can't determine the actual index
                let noteIndex = 0
                let detailVC = NoteDetailViewController(note: note, index: noteIndex)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }
    
    private func navigateToPassword(with id: String) {
        // Password index: Used to find the password in the array
        if let index = Int(id) {
            let detailVC = PasswordDetailViewController()
            detailVC.entryIndex = index
            
            // We can't access the passwords directly here, just set the index
            // The PasswordDetailViewController will load the entry when it appears
            
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    private func navigateToContact(with id: String) {
        // Contact index: Used to find the contact in the array
        if let index = Int(id) {
            let detailVC = ContactDetailViewController()
            detailVC.contactIndex = index
            
            // We can't access the contacts directly here, just set the index
            // The ContactDetailViewController will load the contact when it appears
            
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    private func navigateToPGPMessage(with id: String) {
        // For PGP messages, just use a simple navigation to PGP conversations list
        // The specific conversation view isn't easily accessible without the proper ContactPGP object
        let conversationsVC = ConversationsViewController()
        navigationController?.pushViewController(conversationsVC, animated: true)
    }
    
    private func navigateToFile(with id: String) {
        // File URL: Points directly to the file
        if let fileURL = URL(string: id) {
            let previewVC = FilePreviewViewController()
            previewVC.fileURL = fileURL
            navigationController?.pushViewController(previewVC, animated: true)
        }
    }
    
    private func navigateToTodo(with id: String) {
        // CoreData ID: Convert to ObjectID and fetch the TODO item
        if let objectID = objectID(from: id) {
            if let todoItem = try? CoreDataManager.shared.context.existingObject(with: objectID) as? TODOItem {
                let todoVC = TODOViewController()
                todoVC.highlightItem = todoItem
                navigationController?.pushViewController(todoVC, animated: true)
            }
        }
    }
    
    private func navigateToVoiceMemo(with id: String) {
        // File URL: Points directly to the voice memo file
        if let fileURL = URL(string: id) {
            let playerVC = VoiceMemoPlayerViewController()
            playerVC.memoURL = fileURL
            navigationController?.pushViewController(playerVC, animated: true)
        }
    }
    
    private func navigateToEvent(with id: String) {
        // Event UUID: Used to find the event
        if let uuid = UUID(uuidString: id) {
            if let event = CalendarManager.shared.getEvent(withID: uuid) {
                let detailVC = EventDetailViewController(event: event)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isShowingRecentSearches ? recentSearches.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingRecentSearches {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentSearchCell", for: indexPath)
            cell.textLabel?.text = recentSearches[indexPath.row]
            cell.imageView?.image = UIImage(systemName: "clock")
            return cell
        } else {
            // Create a cell with subtitle style for search results
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SearchCell")
            let result = searchResults[indexPath.row]
            
            cell.textLabel?.text = result.title
            cell.detailTextLabel?.text = result.preview
            
            let icon: String
            switch result.type {
            case .note: icon = "note.text"
            case .password: icon = "lock"
            case .contact: icon = "person"
            case .pgpMessage: icon = "envelope.badge.shield"
            case .file: icon = "doc"
            case .todo: icon = "checklist"
            case .voiceMemo: icon = "mic"
            case .event: icon = "calendar"
            }
            cell.imageView?.image = UIImage(systemName: icon)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isShowingRecentSearches && !recentSearches.isEmpty {
            return "Recent Searches"
        }
        return nil
    }
}

// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isShowingRecentSearches {
            let query = recentSearches[indexPath.row]
            searchController.searchBar.text = query
            performSearch(query: query)
        } else {
            let result = searchResults[indexPath.row]
            navigateToResult(result)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        performSearch(query: query)
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isShowingRecentSearches = true
        loadRecentSearches()
    }
}

// MARK: - SearchFilterDelegate

extension SearchViewController: SearchFilterDelegate {
    func didUpdateFilter(_ filter: SearchFilter) {
        currentFilter = filter
        if let query = searchController.searchBar.text, !query.isEmpty {
            performSearch(query: query)
        }
    }
}