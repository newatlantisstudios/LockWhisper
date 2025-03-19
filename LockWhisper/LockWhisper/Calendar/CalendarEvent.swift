import Foundation

struct CalendarEvent: Codable {
    let id: UUID
    var title: String
    var location: String?
    var notes: String?
    var startDate: Date
    var endDate: Date
    var color: String // Hex color code for the event
    
    init(id: UUID = UUID(), title: String, location: String? = nil, notes: String? = nil, startDate: Date, endDate: Date, color: String = "#007AFF") {
        self.id = id
        self.title = title
        self.location = location
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.color = color
    }
}
