//
//  ItemEntity+CoreDataClass.swift
//  ShoppingList
//
//  Created by Spandana Batchu on 2/19/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//
//

import Foundation
import CoreData


public class ItemEntity: NSManagedObject {

}

extension ItemEntity: EntityGeneratable {
    
    func populate(withJSONDerivable model: Item) {
        name = model.name
        purchased = model.purchased
    }
    
    func item() -> Item {
        let item = Item(name: name, purchased: purchased)
        return item
    }
    
}
