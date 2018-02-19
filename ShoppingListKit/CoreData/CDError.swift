//
//  CDError.swift
//
//  Copyright © 2015 MutualMobile. All rights reserved.
//

import Foundation

enum CDError: Error, CustomStringConvertible {
    case couldNotCreateManagedObjectModel
    case fileNotFound
    case modalDoesNotExist(String)
    case storeURLNotFound(String)
    
    var description: String {
        get {
            switch self {
            case .couldNotCreateManagedObjectModel:
                return "Could not create Managed Object Modal."
            case .fileNotFound:
                return "File to copy not found in bundle."
            case .modalDoesNotExist(let name):
                return "Could not find \(name) modal in Main Bundle."
            case .storeURLNotFound(let name):
                return "Could not create store URL for \(name) modal in documents directory."
            }
        }
    }
}
