//
//  HashableObject.swift
//
//
//  Created by Ilya Kuznetsov on 15/05/2024.
//

import Foundation

public protocol HashableObject: AnyObject, Hashable { }

public extension HashableObject {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
