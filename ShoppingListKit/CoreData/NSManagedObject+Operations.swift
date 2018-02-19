//
//  NSManagedObject+Operations.swift
//
//  Copyright © 2015 MutualMobile. All rights reserved.
//

import Foundation
import CoreData

enum FetchError: Error, CustomStringConvertible {
    case queryDidNotReturnExpectedResponse(NSFetchRequestResult.Type, NSFetchRequestResult.Type)
    case unkonwn
    
    var description: String {
        get {
            switch self {
            case .queryDidNotReturnExpectedResponse(let actualType, let expectedType):
                return "Query returned \(actualType) objects but expected result was \(expectedType) objects"
            case .unkonwn:
                return "Unknown Error."
            }
        }
    }
}

extension NSManagedObject {
    
    
    static func createEntityInContext(_ context: NSManagedObjectContext) -> Self {
        return createInContext(context)
    }
    
    private class func createInContext<T>(_ context: NSManagedObjectContext) -> T {
        let classname = String(describing: self)
        let object = NSEntityDescription.insertNewObject(forEntityName: classname, into: context) as! T
        return object
    }
    
    //MARK: Count operations
    static func countInContext(_ context: NSManagedObjectContext) -> Int {
        return countInContext(context, predicate: nil)
    }
    
    static func countInContext(_ context: NSManagedObjectContext, predicate: NSPredicate?) -> Int {
        let fetchRequest = fetchRequestInContext(context, predicate: predicate)
        var count = 0
        context.performAndWait { () -> Void in
            do {
                try count = context.count(for: fetchRequest)
            } catch {
            
            }
            
        }
        return count
    }
    
    //MARK: Request generation
    private static func fetchRequestInContext(_ context: NSManagedObjectContext, predicate:NSPredicate?) -> NSFetchRequest<NSManagedObject> {
        return fetchRequestInContext(context, sortingKey: nil, ascending: false, predicate: predicate)
    }
    
    private static func fetchRequestInContext(_ context: NSManagedObjectContext, sortingKey: String?, ascending: Bool?, predicate: NSPredicate?) -> NSFetchRequest<NSManagedObject> {
        let fetchRequest = simpleFetchRequestInConext(context)
        if let sortTerm = sortingKey{
            let filtered = fetchRequest.entity?.properties.filter(){
                return $0.name == sortTerm
            }
            if let _filtered = filtered {
                if (_filtered.count > 0) == true{
                    let sorter = NSSortDescriptor(key: sortTerm, ascending: ascending!)
                    fetchRequest.sortDescriptors = [sorter]
                }
            }
        }
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
   
    private static func simpleFetchRequestInConext<T: NSManagedObject>(_ context: NSManagedObjectContext) -> NSFetchRequest<T> {
        let entity = NSEntityDescription.entity(forEntityName: String(describing: self), in: context)
        let request = NSFetchRequest<T>()
        request.entity = entity
        return request
    }
    
    private static func asynchronousFecthRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, completion:((NSAsynchronousFetchResult<T>) -> Void)?) -> NSAsynchronousFetchRequest<T> {
        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: request, completionBlock: completion)
        return asyncFetchRequest
    }
    
    //MARK: Fetch operations
    static func fetchAll<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, completion: (([T]?, Error?) -> Void )?) {
        fetchAll(context, asynchronously: asynchronously, sortingKey: nil, ascending: nil, predicate: nil, completion: completion)
    }
    
    static func fetchAll<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, sortingKey: String?, ascending: Bool?, completion: (([T]?, Error?) -> Void )?) {
        fetchAll(context, asynchronously: asynchronously, sortingKey: sortingKey, ascending: ascending, predicate: nil, completion: completion)
    }
    
    static func fetchAll<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, predicate: NSPredicate?, completion: (([T]?, Error?) -> Void )?) {
        fetchAll(context, asynchronously: asynchronously, sortingKey: nil, ascending: nil, predicate: predicate, completion: completion)
    }
    
    static func fetchAll<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, sortingKey: String?, ascending: Bool?, predicate: NSPredicate?, completion: (([T]?, Error?) -> Void )?) {
        let fetchRequest = fetchRequestInContext(context, sortingKey: sortingKey, ascending: ascending, predicate: predicate)
        executeRequest(fetchRequest, context: context, asynchronously: asynchronously) { (objects, error) in
            guard let response = objects else {
                completion?(nil, error ?? FetchError.unkonwn)
                return
            }
            
            guard let firstObject = response.first else {
                completion?([], error)
                return
            }
            guard let _ = firstObject as? T else {
                completion?(nil, FetchError.queryDidNotReturnExpectedResponse(type(of: firstObject) as NSFetchRequestResult.Type, T.self as NSFetchRequestResult.Type))
                return
            }
            completion?(response as? [T], error)
        }
    }
    
    //MARK: Fetch first operations
    static func fetchFirst<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, completion: ((T?, Error?) -> Void )?) {
        fetchFirst(context, asynchronously: asynchronously, sortingKey: nil, ascending: nil, predicate: nil, completion: completion)
    }
    
    static func fetchFirst<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, sortingKey: String?, ascending: Bool?, completion: ((T?, Error?) -> Void )?) {
        fetchFirst(context, asynchronously: asynchronously, sortingKey: sortingKey, ascending: ascending, predicate: nil, completion: completion)
    }
    
    static func fetchFirst<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, predicate: NSPredicate?, completion: ((T?, Error?) -> Void )?) {
        fetchFirst(context, asynchronously: asynchronously, sortingKey: nil, ascending: nil, predicate: predicate, completion: completion)
    }
    
    static func fetchFirst<T: NSManagedObject>(_ context: NSManagedObjectContext, asynchronously: Bool, sortingKey: String?, ascending: Bool?, predicate: NSPredicate?, completion: ((T?, Error?) -> Void )?) {
        let fetchRequest = fetchRequestInContext(context, sortingKey: sortingKey, ascending: ascending, predicate: predicate)
        executeRequest(fetchRequest, context: context, asynchronously: asynchronously, completion: { (result, error) -> Void in
            guard let response = result else {
                completion?(nil, error ?? FetchError.unkonwn)
                return
            }
            
            guard let firstObject = response.first else {
                completion?(nil, error)
                return
            }
            guard let castedObject = firstObject as? T else {
                completion?(nil, FetchError.queryDidNotReturnExpectedResponse(type(of: firstObject) as NSFetchRequestResult.Type, T.self as NSFetchRequestResult.Type))
                return
            }
            completion?(castedObject, error)
        })
    }
    
    
    //MARK: Execute Requests
    static func executeRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext, asynchronously: Bool, completion: (([T]?, Error?) -> Void )?) {
        if asynchronously == true{
            let closure = closureWithAsynchronousFetchRequest(request, context: context, completion: completion)
            context.perform(closure)
        }
        else{
            let closure = closureForRequest(request, context: context,  completion: completion)
            context.performAndWait(closure)
        }
    }
    
    private static func closureForRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext, completion: (([T]?, Error?) -> Void )?) -> (() -> Void) {
        let closure = {
            do{
                let result = try context.fetch(request)
                completion?(result, nil)
            }
            catch {
                completion?(nil, error)
            }
        }
        return closure
    }
    
    private static func closureWithAsynchronousFetchRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, context: NSManagedObjectContext, completion: (([T]?, Error?) -> Void )?) -> (() -> Void) {
        let closure = {
            let resultBlock: ((NSAsynchronousFetchResult<NSManagedObject>) -> Void)? = { (result) -> Void in
                completion?(result.finalResult as? [T], nil)
            }
            let asyncFetchRequest = asynchronousFecthRequest(request as! NSFetchRequest<NSManagedObject>, completion: resultBlock)
            do{
                try context.execute(asyncFetchRequest)
            }
            catch let error {
                completion?(nil, error)
            }
        }
        return closure
    }
    
    //MARK: Delete operations
    func deleteEntity() {
        deleteInContext(managedObjectContext!)
    }
    
    func deleteInContext(_ context: NSManagedObjectContext) {
        context.delete(self)
    }
    
    static func deleteAllInContext(_ context: NSManagedObjectContext) {
        deleteAllInContext(context, predicate: nil)
    }
    
    static func deleteAllInContext(_ context: NSManagedObjectContext, predicate: NSPredicate?) {
        let fetchRequest = fetchRequestInContext(context, predicate: predicate)
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        executeRequest(fetchRequest, context: context, asynchronously: false) { (result, error) -> Void in
            if let resultObjects = result{
                for object in resultObjects {
                    object.deleteInContext(context)
                }
            }
        }
    }
    
    
    //MARK: Save operations    
    func saveToDisk(_ asynchronously: Bool, completion: ((Bool, NSError?) -> Void)?) {
        let context = managedObjectContext!
        context.saveChangesToDiskAsynchronously(asynchronously, completion: completion)
    }
    
    static func batchUpdate(_ updateInfo: [AnyHashable: Any]?, predicate: NSPredicate?, context: NSManagedObjectContext, asynchronously: Bool ,completion: ((AnyObject?, NSError?) -> Void )?){
        let entity = NSEntityDescription.entity(forEntityName: String(describing: self), in: context)
        let batchUpdateRequest = NSBatchUpdateRequest(entity: entity!)
        batchUpdateRequest.propertiesToUpdate = updateInfo
        batchUpdateRequest.resultType = .updatedObjectIDsResultType
        batchUpdateRequest.affectedStores = context.persistentStoreCoordinator?.persistentStores
        batchUpdateRequest.predicate = predicate
        let blockToPerform =  { () -> Void in
            do{
                let batchUpdateResult = try context.execute(batchUpdateRequest)
                completion?(batchUpdateResult, nil)
            }
            catch let error as NSError{
                completion?(nil, error)
            }
        }
        if asynchronously {
            context.perform(blockToPerform)
        } else {
            context.performAndWait(blockToPerform)
        }
    }
    
    static func batchDelete(_ updateInfo: [AnyHashable: Any], predicate: NSPredicate?, context: NSManagedObjectContext, completion: ((AnyObject?, NSError?) -> Void )?){
        let fetchRequest = fetchRequestInContext(context, predicate: predicate)
        let batchUpdateRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        batchUpdateRequest.resultType = .resultTypeObjectIDs
        batchUpdateRequest.affectedStores = context.persistentStoreCoordinator?.persistentStores
        context.perform { () -> Void in
            do{
                let batchUpdateResult = try context.execute(batchUpdateRequest)
                completion?(batchUpdateResult, nil)
            }
            catch let error as NSError{
                completion?(nil, error)
            }
        }
    }
}
