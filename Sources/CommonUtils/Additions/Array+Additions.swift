//
//  Array+Additions.swift
//  
//
//  Created by Ilya Kuznetsov on 23/12/2022.
//

import Foundation

public extension Array {
    
    subscript (safe index: Index) -> Element? {
        if index >= 0 && index < count {
            return self[index]
        }
        return nil
    }
    
    mutating func appendSafe(_ element: Element?) {
        if let element = element {
            append(element)
        }
    }
    
    func appending(_ element: Element?) -> Self {
        if let element = element {
            var result = self
            result.append(element)
            return result
        }
        return self
    }
}
