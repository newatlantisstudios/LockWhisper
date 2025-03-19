import Foundation
import CoreData

// This extension will allow us to create a TODO item and use it with CoreData
extension NSManagedObject {
    
    // Create a TODO item entity in Core Data
    class func createTODOItem(title: String, completed: Bool = false, createdAt: Date = Date(), in context: NSManagedObjectContext) -> NSManagedObject? {
        if let entity = NSEntityDescription.entity(forEntityName: "TODOItem", in: context) {
            let todoItem = NSManagedObject(entity: entity, insertInto: context)
            todoItem.setValue(title, forKey: "title")
            todoItem.setValue(completed, forKey: "completed")
            todoItem.setValue(createdAt, forKey: "createdAt")
            
            return todoItem
        }
        return nil
    }
}
