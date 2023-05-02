//
//  Box.swift
//  
//
//  Created by Ilya Kuznetsov on 02/05/2023.
//

import Foundation

public protocol BoxProtocol: AnyObject {
    associatedtype Value: Identifiable
    
    var value: Value { get set }
    
    init(_ value: Value)
}

@dynamicMemberLookup
public final class Box<Value: Identifiable>: ObservableObject, Hashable, BoxProtocol {
    
    @AtomicPublished public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public convenience init?(_ value: Value?) {
        if let value = value {
            self.init(value)
        } else {
            return nil
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value.id)
    }
    
    public static func == (lhs: Box<Value>, rhs: Box<Value>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        value[keyPath: keyPath]
    }
}

public extension Array where Element: BoxProtocol {
    
    func update(newValues: [Element.Value]) -> Self {
        let currentItems = reduce(into: [:]) { $0[$1.value.id] = $1 }
        var added = Set<Element.Value.ID>()
        
        return newValues.compactMap {
            if added.contains($0.id) { return nil }
            added.insert($0.id)
            
            if let currentItem = currentItems[$0.id] {
                currentItem.value = $0
                return currentItem
            } else {
                return .init($0)
            }
        }
    }
}
