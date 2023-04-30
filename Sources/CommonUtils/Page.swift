//
//  Page.swift
//

import Foundation

public struct Page<T> {
    public let items: [T]
    public let next: AnyHashable?
    
    public init(items: [T], next: AnyHashable?) {
        self.items = items
        self.next = next
    }
}
