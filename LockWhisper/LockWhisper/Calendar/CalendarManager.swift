import Foundation
import CryptoKit

/// CalendarManager handles the storage, retrieval, and management of calendar events
/// Uses encryption to ensure event data is securely stored
class CalendarManager {
    static let shared = CalendarManager()
    
    private let eventStorageKey = "com.lockwhisper.calendarEvents"
    private let encryptionKey = "com.lockwhisper.calendarKey"
    private var events: [CalendarEvent] = []
    
    private init() {
        loadEvents()
    }
    
    // MARK: - Encryption
    
    private func getEncryptionKey() -> SymmetricKey {
        if let savedKeyData = CalendarKeychainHelper.standard.read(service: encryptionKey, account: "calendar") {
            return SymmetricKey(data: savedKeyData)
        }
        
        // Create a new key if none exists
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Save the key to the keychain
        CalendarKeychainHelper.standard.save(keyData, service: encryptionKey, account: "calendar")
        
        return key
    }
    
    private func encrypt(data: Data) -> Data? {
        do {
            let key = getEncryptionKey()
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    private func decrypt(data: Data) -> Data? {
        do {
            let key = getEncryptionKey()
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Management
    
    func loadEvents() {
        guard let encryptedData = UserDefaults.standard.data(forKey: eventStorageKey) else {
            events = []
            return
        }
        
        guard let decryptedData = decrypt(data: encryptedData) else {
            print("Failed to decrypt calendar events")
            events = []
            return
        }
        
        do {
            events = try JSONDecoder().decode([CalendarEvent].self, from: decryptedData)
        } catch {
            print("Error loading calendar events: \(error)")
            events = []
        }
    }
    
    func saveEvents() {
        do {
            let jsonData = try JSONEncoder().encode(events)
            
            if let encryptedData = encrypt(data: jsonData) {
                UserDefaults.standard.set(encryptedData, forKey: eventStorageKey)
            } else {
                print("Failed to encrypt calendar events")
            }
        } catch {
            print("Error saving calendar events: \(error)")
        }
    }
    
    // MARK: - Event CRUD Operations
    
    func getAllEvents() -> [CalendarEvent] {
        return events
    }
    
    func getEvents(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return events.filter { event in
            // Event starts on this day
            if calendar.isDate(event.startDate, inSameDayAs: date) {
                return true
            }
            
            // Event ends on this day
            if calendar.isDate(event.endDate, inSameDayAs: date) {
                return true
            }
            
            // Event spans over this day
            if event.startDate < startOfDay && event.endDate > endOfDay {
                return true
            }
            
            return false
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        saveEvents()
    }
    
    func updateEvent(_ updatedEvent: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == updatedEvent.id }) {
            events[index] = updatedEvent
            saveEvents()
        }
    }
    
    func deleteEvent(withID id: UUID) {
        events.removeAll { $0.id == id }
        saveEvents()
    }
    
    func getEvent(withID id: UUID) -> CalendarEvent? {
        return events.first { $0.id == id }
    }
}
