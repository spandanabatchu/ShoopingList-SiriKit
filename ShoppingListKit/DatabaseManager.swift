//
//  DatabaseManager.swift
//  ShoppingList
//
//  Created by Spandana Batchu on 2/21/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import Foundation

let AppGroup = "group.com.mutualmobile.sample.intent"
let CartKey = "Cart"

class DatabaseManager {
    
    public static let sharedDBManager = DatabaseManager()
    let sharedDefaults = UserDefaults(suiteName: AppGroup)
    var savedCart = [Item]()
    
    init() {
        if let cartData = sharedDefaults?.value(forKey: CartKey) as? [Data] {
            savedCart = cartData.flatMap { return Item(data: $0) }
        }
    }
    
    func shoppingCart() -> [Item]? {
        return savedCart
    }
    
    func purchaseItem(itemName: String) {
        for (index, item) in savedCart.enumerated() {
            if item.name == itemName {
                let newItem = Item(name: itemName, purchased: true)
                savedCart.remove(at: index)
                savedCart.insert(newItem, at: index)
                save()
                return
            }
        }
    }
    
    func add(_ item: Item) {
        savedCart.append(item)
        save()
    }
    
    func fetchItem(itemName: String) -> Item? {
        for item in savedCart {
            if item.name == itemName {
                return item
            }
        }
        return nil
    }
    
    private func save() {
        let itemsData = savedCart.map { $0.encode() }
        sharedDefaults?.set(itemsData, forKey: CartKey)
        sharedDefaults?.synchronize()
    }
    
}
