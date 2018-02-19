//
//  CoreDataStackController.swift
//
//  Copyright © 2015 MutualMobile. All rights reserved.
//

import Foundation
import CoreData

struct StoreConfiguration {
    var storeType: String
    var name: String?
    static func defaultStoreConfiguration() -> StoreConfiguration {
        return StoreConfiguration(storeType: NSSQLiteStoreType, name: nil)
    }
}

class CoreDataStackController {
    private(set) var mainQueueContext: NSManagedObjectContext!
    private(set) var rootContext: NSManagedObjectContext!
    private(set) var dataModelName: String
    private(set) var storeConfigurations: [StoreConfiguration]
    
    init (dataModelName: String, configurations: [StoreConfiguration] = [StoreConfiguration.defaultStoreConfiguration()]) {
        self.dataModelName = dataModelName
        storeConfigurations = configurations
    }
    
    func setupDBConnection(_ prepopulated: Bool) throws -> Void {
        if prepopulated == true {
            try copyDefaultStoreIfNeeded()
        }
        try setUpStack()
    }
    
    private func setUpStack() throws -> Void {
        let modelURL = Bundle.main.url(forResource: dataModelName, withExtension: "momd")
        guard let managedObjectModelURL = modelURL else {
            throw CDError.modalDoesNotExist(dataModelName)
            
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelURL) else {
            throw CDError.couldNotCreateManagedObjectModel
        }
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        rootContext = NSManagedObjectContext.privateQueueManagedObjectContext()
        rootContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        rootContext.persistentStoreCoordinator = storeCoordinator
        mainQueueContext = NSManagedObjectContext.mainQueueContextWithParentContext(rootContext)
        return try addPersistentStore()
    }
    
    
    private func addPersistentStore() throws -> Void {
        let persistentStoreCoordinator = rootContext.persistentStoreCoordinator
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption:["journal_mode":"DELETE"]] as [String : Any]
        if let storeURLValue = storeURL() {
            for config in storeConfigurations {
                try persistentStoreCoordinator?.addPersistentStore(ofType: config.storeType, configurationName: config.name, at: storeURLValue, options: options)
            }
        } else {
            throw CDError.storeURLNotFound(dataModelName)
        }
    }
    
    private func storeURL() -> URL? {
        let fileManager = FileManager.default
        let groupDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mutualmobile.sample.intent")!
        let databaseName = dataModelName + ".sqlite"
        return groupDirectory.appendingPathComponent(databaseName)
    }
    
    
    func rootChildContext() -> NSManagedObjectContext? {
        guard let rootContextValue = rootContext else {
            return nil
        }
        return NSManagedObjectContext.privateQueueContextWithParentContext(rootContextValue)
    }
    
    func mainQueueChildContext() -> NSManagedObjectContext? {
        guard let rootContextValue = mainQueueContext else {
            return nil
        }
        return NSManagedObjectContext.privateQueueContextWithParentContext(rootContextValue)
    }
    
    
    private func copyDefaultStoreIfNeeded() throws -> Void {
        guard let storeURLValue = storeURL() else {
            throw CDError.storeURLNotFound(dataModelName)
        }
        guard FileManager.default.fileExists(atPath: storeURLValue.path) == false else {
            return
        }
        guard let preloadPath = Bundle.main.path(forResource: dataModelName, ofType: "sqlite") else {
            throw CDError.fileNotFound
        }
        let preloadURL = URL(fileURLWithPath: preloadPath)
        try FileManager.default.copyItem(at: preloadURL, to: storeURLValue)
    }
    
    func saveToDiskAsynchronously(_ async: Bool, completion: ((Bool, NSError?)->Void)?) {
        saveToDiskAsynchronously(mainQueueContext, async: async, completion: completion)
    }
    
    func saveToDiskAsynchronously(_ context:NSManagedObjectContext, async: Bool, completion: ((Bool, NSError?)->Void)?) {
        context.saveChangesToDiskAsynchronously(async, completion: completion)
    }
    
    func discardChangesOfMainQueueContext() -> Void {
        discardChanges(mainQueueContext)
    }
    
    func discardChanges(_ context: NSManagedObjectContext) -> Void {
        context.rollback()
    }
}
