//
//  Extractable.swift
//  
//
//  Created by Ilya Kuznetsov on 07/05/2023.
//

import Foundation

public protocol Extractable {
    
    func extractValue<T>(of type: T.Type) -> T?
}

public extension Extractable {
    
    func extractValue<T>(of type: T.Type) -> T? {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if let value = child.value as? T {
                return value
            } else {
                let mirror = Mirror(reflecting: child.value)
                
                for child in mirror.children {
                    if let value = child.value as? T {
                        return value
                    }
                }
            }
        }
        return nil
    }
}
