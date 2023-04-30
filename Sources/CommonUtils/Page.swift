//
//  Page.swift
//

import Foundation

public struct Page<T: Hashable>: Equatable {
    public let items: [T]
    public let next: AnyHashable?
    
    public init(items: [T] = [], next: AnyHashable? = nil) {
        self.items = items
        self.next = next
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.items.count != rhs.items.count || lhs.next != rhs.next {
            return false
        }
        return lhs.items == rhs.items
    }
}
