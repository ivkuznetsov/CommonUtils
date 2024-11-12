//
//  ObservableValue.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 11/10/2024.
//

import Combine
import Foundation
import SwiftUI

@propertyWrapper
public final class ObservedValue<T: Sendable>: ObservableObject, Sendable, HashableObject {
    public nonisolated let publisher: CurrentValueSubject<T, Never>
    private nonisolated let lock = RWLock()
    @MainActor private var ownerPublisher: ObservableObjectPublisher?
    
    public nonisolated var wrappedValue: T {
        get { lock.read { publisher.value } }
        set {
            let shouldPublish = lock.write {
                if let currentValue = publisher.value as? any Equatable,
                   let newValue = newValue as? any Equatable,
                    currentValue.isEqual(newValue) {
                    return false
                }
                publisher.send(newValue)
                return true
            }
            
            if shouldPublish {
                Task { @MainActor in
                    self.objectWillChange.send()
                    self.ownerPublisher?.send()
                }
            }
        }
    }
    
    public init(_ value: T, owner: (any ObservableObject)? = nil) {
        publisher = .init(value)
    }
    
    public var binding: Binding<T> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public func republish(_ owner: any ObservableObject ) {
        Task { @MainActor in ownerPublisher = owner.objectWillChange as? ObservableObjectPublisher }
    }
    
    public nonisolated func callAsFunction() -> T { wrappedValue }
    
    public init(from decoder: any Decoder) throws where T: Codable {
        publisher = .init(try .init(from: decoder))
    }
    
    public nonisolated func encode(to encoder: any Encoder) throws where T: Codable {
        try wrappedValue.encode(to: encoder)
    }
}

extension Equatable {
    
    func isEqual(_ other: any Equatable) -> Bool {
        if let other = other as? Self {
            return self == other
        }
        return false
    }
}

extension ObservedValue: Codable where T: Codable {
    
    public func store(in key: String, defaultValue: T, storage: UserDefaults = .standard) {
        lock.write { publisher.send(UserDefaults.load(key: key, storage: storage) ?? defaultValue) }
        publisher.dropFirst().sink { UserDefaults.store($0, key: key, storage: storage) }.retained(by: self)
    }
}
