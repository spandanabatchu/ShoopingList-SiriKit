//
//  ItemEntity+CoreDataProperties.swift
//  ShoppingList
//
//  Created by Spandana Batchu on 2/19/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//
//

import Foundation
import CoreData


extension ItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ItemEntity> {
        return NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var purchased: Bool

}
