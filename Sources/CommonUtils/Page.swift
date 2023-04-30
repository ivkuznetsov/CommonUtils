//
//  Page.swift
//

import Foundation

public struct Page<Item> {
    public let items: [Item]
    public let next: AnyHashable?
    
    public init(items: [Item] = [], next: AnyHashable? = nil) {
        self.items = items
        self.next = next
    }
}

extension Page: Equatable where Item: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.items.count != rhs.items.count || lhs.next != rhs.next {
            return false
        }
        return lhs.items == rhs.items
    }
}
