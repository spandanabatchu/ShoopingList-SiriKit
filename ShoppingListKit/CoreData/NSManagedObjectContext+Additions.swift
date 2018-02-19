//
//  NSManagedObjectContext+Operations.swift
//
//  Copyright © 2015 MutualMobile. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    static func privateQueueManagedObjectContext() -> NSManagedObjectContext {
        return NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    }
    
    static func mainQueueManagedObjectContext() -> NSManagedObjectContext {
        return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }
    
    static func privateQueueContextWithParentContext(_ parentContext: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = privateQueueManagedObjectContext()
        context.parent = parentContext
        return context
    }
    
    static func mainQueueContextWithParentContext(_ parentContext: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = mainQueueManagedObjectContext()
        context.parent = parentContext
        return context
    }
    
    func saveChangesToDiskAsynchronously(_ async: Bool, completion: ((Bool, NSError?) -> Void)?) {
        let saveClosure = {
            let saveSuccessBlock = {
                if let parentContext = self.parent {
                    parentContext.saveChangesToDiskAsynchronously(async,completion:completion)
                } else {
                    completion?(true,nil)
                }
            }
            if self.hasChanges {
                do {
                    try self.save()
                    saveSuccessBlock()
                } catch let error {
                    completion?(false, error as NSError)
                }
            }
            else {
                saveSuccessBlock()
            }
        }
        if async == true {
            perform(saveClosure)
        } else {
            performAndWait(saveClosure)
        }
    }
}
