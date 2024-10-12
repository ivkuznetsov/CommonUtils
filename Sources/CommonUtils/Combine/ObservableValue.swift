//
//  ObservableValue.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 11/10/2024.
//

import Combine
import Foundation

@propertyWrapper
public actor ObservableValue<T: Sendable>: ObservableObject {
    public nonisolated let value: CurrentValueSubject<T, Never>
    public nonisolated var wrappedValue: T { value.value }
    
    public init(_ value: T) {
        self.value = .init(value)
    }
    
    @MainActor
    public func update(_ value: T) {
        self.value.send(value)
        self.objectWillChange.send()
    }
    
    public nonisolated func callAsFunction() -> T { wrappedValue }
    
    public init(from decoder: any Decoder) throws where T: Codable {
        self.value = .init(try .init(from: decoder))
    }
    
    public nonisolated func encode(to encoder: any Encoder) throws where T: Codable {
        try wrappedValue.encode(to: encoder)
    }
}

extension ObservableValue: Codable where T: Codable { }

@propertyWrapper
public struct ObservableStorage<Value: Actor & ObservableObject & Codable>: Sendable {
    
    public let wrappedValue: Value
    private nonisolated let observer: AnyCancellable
    
    public init(_ key: String, storage: UserDefaults = .standard, defaultValue: Value) {
        if let result = storage.object(forKey: key) as? Value {
            wrappedValue = result
        } else if let result = storage.object(forKey: key) as? Data, let value = try? Value.decode(result) {
            wrappedValue = value
        } else {
            wrappedValue = defaultValue
        }
        let value = wrappedValue
        observer = wrappedValue.sink {
            if let value = value as? NSCoding {
                storage.set(value, forKey: key)
            } else if let value = try? value.toData() {
                storage.set(value, forKey: key)
            }
        }
    }
}
