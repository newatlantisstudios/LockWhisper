import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private var _persistentContainer: NSPersistentContainer?
    
    var persistentContainer: NSPersistentContainer {
        if _persistentContainer == nil {
            updatePersistentContainer()
        }
        return _persistentContainer!
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        updatePersistentContainer()
    }
    
    private func updatePersistentContainer() {
        // Get the appropriate store name based on current auth mode
        let storeName = FakePasswordManager.shared.isInFakeMode ? "NotepadModelFake" : "NotepadModel"
        
        let container = NSPersistentContainer(name: "NotepadModel")
        
        // Customize the store URL for fake mode
        if FakePasswordManager.shared.isInFakeMode {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storeURL = documentsDirectory.appendingPathComponent("\(storeName).sqlite")
            
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        _persistentContainer = container
    }
    
    func reloadForCurrentAuthMode() {
        // Clear the current container and reload with appropriate store
        _persistentContainer = nil
        updatePersistentContainer()
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
