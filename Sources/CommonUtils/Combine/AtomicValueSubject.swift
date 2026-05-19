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
    public nonisolated let publisher: CurrentValueSubject<T, Never>
    private nonisolated let lock = RWLock()
    
    public nonisolated var wrappedValue: T {
        get { lock.read { publisher.value } }
        set { mutate { $0 = newValue } }
    }
    
    public init(_ value: T) {
        publisher = .init(value)
    }
    
    public var binding: Binding<T> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        lock.write {
            var newValue = publisher.value
            mutation(&newValue)
            
            if let currentValue = publisher.value as? any Equatable,
               let newValue = newValue as? any Equatable,
                currentValue.isEqual(newValue) {
                return
            }
            publisher.send(newValue)
        }
    }
    
    public nonisolated func callAsFunction() -> T { wrappedValue }
    
    public subscript<S>(dynamicMember keyPath: KeyPath<T, S>) -> S {
        lock.read { publisher.value[keyPath: keyPath] }
    }
    
    public subscript<S>(dynamicMember keyPath: WritableKeyPath<T, S>) -> S {
        get { lock.read { publisher.value[keyPath: keyPath] } }
        set { mutate { $0[keyPath: keyPath] = newValue } }
    }
    
    public init(from decoder: any Decoder) throws where T: Codable {
        publisher = .init(try .init(from: decoder))
    }
    
    public nonisolated func encode(to encoder: any Encoder) throws where T: Codable {
        try wrappedValue.encode(to: encoder)
    }
}

extension AtomicValueSubject: Codable where T: Codable {
    
    public func store(in key: String, defaultValue: T, storage: UserDefaults = .standard) {
        lock.write { publisher.send(UserDefaults.load(key: key, storage: storage) ?? defaultValue) }
        publisher.dropFirst().sink { UserDefaults.store($0, key: key, storage: storage) }.retained(by: self)
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
