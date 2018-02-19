//
//  DatabaseManager.swift
//
//  Copyright © 2016 Mutual Mobile. All rights reserved.
//

import Foundation
import CoreData


protocol DescriptiveErrorType: Error, CustomStringConvertible {
    var title: String { get }
}

extension DescriptiveErrorType {
    
    var title: String {
        get {
            return "Error"
        }
    }
}

//MARK: DBManager Constants

private struct DBManagerConstants {
    struct DBStackConstants {
        static let stackName = "ShoppingList"
    }
    struct DBErrorConstants {
        static let databaseNotSetUp = "Database not set up"
        static let recordNotFound = "Record not found: "
        static let missingDetails = "Required parameter missing to save entity: "
        static let saveError = "Error occured while saving: "
    }
}

//MARK: DBManager Errors

enum DBManagerError: DescriptiveErrorType {
    case databaseNotSetup
    case dbRecordNotFound(String)
    case dbMissingDetail(String)
    case dbSaveError(String)
    
    var description: String {
        get {
            return error().localizedDescription
        }
    }
    
    func error() -> NSError {
        var errorDescription: String!
        switch self {
        case .databaseNotSetup:
            errorDescription = DBManagerConstants.DBErrorConstants.databaseNotSetUp
        case let .dbRecordNotFound(recordName):
            errorDescription = DBManagerConstants.DBErrorConstants.recordNotFound + recordName
        case let .dbMissingDetail(missingParameter):
            errorDescription = DBManagerConstants.DBErrorConstants.missingDetails + missingParameter
        case let .dbSaveError(saveError):
            errorDescription = DBManagerConstants.DBErrorConstants.saveError + saveError
        }
        let error = NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey:errorDescription])
        return error
    }
}

//MARK: DatabaseManager [Singleton class]
public class DatabaseManager {
    public static let sharedDBManager = DatabaseManager()
    private var stackController: CoreDataStackController!
    fileprivate var workerContext: NSManagedObjectContext!
    fileprivate var mainQueueContext: NSManagedObjectContext!
    private(set) var databaseSetupCompleted = false
    private(set) var databaseSetUpCheck: () throws -> Void = {
        guard sharedDBManager.databaseSetupCompleted else {
            throw DBManagerError.databaseNotSetup
        }
    }
    
    private init() {
        stackController = CoreDataStackController(dataModelName: DBManagerConstants.DBStackConstants.stackName)
    }
    
    public func setUpDBConnection() throws -> Void {
        if databaseSetupCompleted == false {
            try stackController.setupDBConnection(false)
            workerContext = stackController.mainQueueChildContext()
            mainQueueContext = stackController.mainQueueContext
            mainQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            workerContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            databaseSetupCompleted = true
        }
    }
    
    func clearDatabase() throws {
        try databaseSetUpCheck()
        var deleteError: Error?
        workerContext.performAndWait {
            ItemEntity.deleteAllInContext(self.workerContext)
            do {
                try self.saveAndPersist()
            }
            catch {
                deleteError = error
            }
        }
        if let _deleteError = deleteError {
            throw _deleteError
        }
    }
    
    //MARK: Save
    
   public func saveAndPersist() throws -> Void {
        try databaseSetUpCheck()
        var saveError: NSError?
        stackController.saveToDiskAsynchronously(workerContext, async: false, completion: { (success, error) -> Void in
            saveError = error
        })
        if let error = saveError {
            throw DBManagerError.dbSaveError(error.localizedDescription)
        }
    }
    
    func discardAllChanges() -> Void {
        guard databaseSetupCompleted == true else {
            return
        }
        stackController.discardChanges(workerContext)
    }
    
}

//MARK: itemsEntity Database methods
extension DatabaseManager {
    
    func save(_ item: Item, save: Bool) throws -> Void {
        if let _itemEntity = try itemEntity(with: item) {
            try update(item, itemEntity: _itemEntity, save: save)
        } else {
            try createAndSave(item, save: true)
        }
    }
    
    fileprivate func itemEntity(with item: Item) throws -> ItemEntity? {
        var fetchError: Error?
        var fetchedItem: ItemEntity?
        guard let _name = item.name else {
            return nil
        }
        let predicate = NSPredicate(format: "name = %@", _name)
        ItemEntity.fetchFirst(mainQueueContext, asynchronously: false, predicate: predicate) { (itemEntity, error) in
            fetchError = error
            fetchedItem = itemEntity as? ItemEntity
            fetchedItem?.purchased = item.purchased
        }
        if let unwrappedError = fetchError {
            throw unwrappedError
        }
        guard let unwrappedItem = fetchedItem else {
            return nil
        }
        return unwrappedItem
    }
    
    
   public func createAndSave(_ item: Item, save: Bool) throws -> Void {
        try databaseSetUpCheck()
        var saveError: Error?
        workerContext.performAndWait {
            let itemEntity = ItemEntity.createEntityInContext(self.workerContext)
            itemEntity.populate(withJSONDerivable: item)
            if save {
                do {
                    try self.saveAndPersist()
                } catch let error {
                    saveError = error
                }
            }
        }
        if let unwrappedError = saveError {
            throw unwrappedError
        }
    }
    
    func update(_ item: Item, itemEntity: ItemEntity, save: Bool) throws -> Void {
        let itemID = itemEntity.objectID
        var saveError: Error?
        workerContext.performAndWait {
            guard let editableItem = self.workerContext.object(with: itemID) as? ItemEntity else {
                saveError = DBManagerError.dbRecordNotFound("Item")
                return
            }
            editableItem.populate(withJSONDerivable: item)
            if save {
                do {
                    try self.saveAndPersist()
                } catch let error {
                    saveError = error
                }
            }
        }
        if let unwrappedError = saveError {
            throw unwrappedError
        }
    }
    
    public func shoppingCart() throws -> [Item] {
        try databaseSetUpCheck()
        var fetchError: Error?
        var fetchedItems: [ItemEntity]?
        ItemEntity.fetchAll(mainQueueContext, asynchronously: false,
                                predicate: nil) {  (items, error) in
                                    fetchError = error
                                    fetchedItems = items as? [ItemEntity]
        }
        if let unwrappedError = fetchError {
            throw unwrappedError
        }
        guard let unwrappedItems = fetchedItems else {
            return [Item]()
        }
        return shoppinglist(from: unwrappedItems)
    }
    
    private func shoppinglist(from itemEntites: [ItemEntity]) -> [Item] {
        var itemsList = [Item]()
        for itemsEntity in itemEntites {
            let _item = itemsEntity.item()
            itemsList.append(_item)
        }
        return itemsList
    }
    
    public func purchaseItem(itemName: String) {
        do {
            let item = Item(name: itemName, purchased: true)
            if let _itemEntity = try itemEntity(with: item) {
                try update(item, itemEntity: _itemEntity, save: true)
            } else {
             print("failed to purchase item \(itemName) as that item doesnt exist! ")
            }
        } catch let error {
            print("failed to purchase item \(itemName) as there was an error while updating! ")
            print(error)
        }
    }
    
    public func isItemAvailable(itemName: String) -> Bool {
            let item = Item(name: itemName, purchased: true)
        do {
            if let _ = try itemEntity(with: item) {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
}



