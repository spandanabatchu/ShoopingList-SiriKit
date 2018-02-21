//
//  Item.swift
//  ShoppingListKit
//
//  Created by Spandana Batchu on 2/12/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import Foundation

public protocol JSONDerivable {
    
}

public struct Item {
    public var name: String?
    public var purchased: Bool
}

extension Item {
    
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(name, forKey: "name")
        archiver.encode(purchased, forKey: "purchased")
        archiver.finishEncoding()
        return data as Data
    }
    
    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let name = unarchiver.decodeObject(forKey: "name") as? String else { return nil }
        purchased = unarchiver.decodeBool(forKey: "purchased")
        self.name = name
    }
}
