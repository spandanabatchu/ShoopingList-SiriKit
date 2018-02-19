//
//  EntityGeneratable.swift
//  ShoppingListKit
//
//  Created by Spandana Batchu on 2/12/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import Foundation

public protocol JSONDerivable {
    
}

protocol EntityGeneratable {
    
    associatedtype JSONDerivableType: JSONDerivable
    
    func populate(withJSONDerivable model: JSONDerivableType) -> Void
    
}
