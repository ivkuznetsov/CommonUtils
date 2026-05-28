//
//  AtomicValueSubject.swift
//  CommonUtils
//
//  Created by Kuznetsov, Ilia on 19.05.26.
//

import Combine
import SwiftUI

@dynamicMemberLookup
@propertyWrapper
public final class AtomicValueSubject<T: Sendable>: Sendable, HashableObject {
    public nonisolated let publisher = ValuePublisher<T>()
    private nonisolated let value: Atomic<T>
    
    public nonisolated var wrappedValue: T {
        get { value.wrappedValue }
        set { mutate { $0 = newValue } }
    }
    
    public init(_ value: T) {
        self.value = .init(value)
    }
    
    public var binding: Binding<T> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        let publish: T? = value.mutate {
            let currentValue = $0
            mutation(&$0)
            
            if let currentValue = currentValue as? any Equatable,
               let newValue = $0 as? any Equatable,
                currentValue.isEqual(newValue) {
                return nil
            }
            return $0
        }
        
        if let publish {
            publisher.send(publish)
        }
    }
    
    public nonisolated func callAsFunction() -> T { wrappedValue }
    
    public subscript<S>(dynamicMember keyPath: KeyPath<T, S>) -> S {
        value.wrappedValue[keyPath: keyPath]
    }
    
    public subscript<S>(dynamicMember keyPath: WritableKeyPath<T, S>) -> S {
        get { value.wrappedValue[keyPath: keyPath] }
        set { mutate { $0[keyPath: keyPath] = newValue } }
    }
    
    public init(from decoder: any Decoder) throws where T: Codable {
        value = .init(try .init(from: decoder))
    }
    
    public nonisolated func encode(to encoder: any Encoder) throws where T: Codable {
        try wrappedValue.encode(to: encoder)
    }
}

extension AtomicValueSubject: Codable where T: Codable {
    
    public func store(in key: String, defaultValue: T, storage: UserDefaults = .standard) {
        mutate { $0 = UserDefaults.load(key: key, storage: storage) ?? defaultValue }
        publisher.sink { UserDefaults.store($0, key: key, storage: storage) }.retained(by: self)
    }
}

public extension AtomicValueSubject {
    
    @discardableResult
    func didChange(retained: AnyObject? = nil, _ closure: @Sendable @escaping (_ old: T, _ new: T) async -> ()) -> AnyCancellable {
        let result = publisher.scan((Optional<T>.none, self())) { ($0.1, current: $1) }.sinkSendable {
            await closure($0.0!, $0.1)
        }
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
}
