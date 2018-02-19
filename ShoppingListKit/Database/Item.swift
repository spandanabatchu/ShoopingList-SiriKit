//
//  Item.swift
//  ShoppingListKit
//
//  Created by Spandana Batchu on 2/12/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import Foundation

public struct Item: JSONDerivable {
    public var name: String?
    public var purchased: Bool
    
    public init(name: String?, purchased: Bool) {
        self.name = name
        self.purchased = purchased
    }
    
}
