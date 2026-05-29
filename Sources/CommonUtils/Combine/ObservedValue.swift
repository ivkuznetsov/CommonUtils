//
//  ObservableValue.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 11/10/2024.
//

import Combine
import Foundation
import SwiftUI

public protocol ObservedValueProtocol: ObservableObject, Sendable, HashableObject {
    associatedtype T: Sendable
    
    nonisolated var publisher: AtomicValueSubject<T> { get }
    
    nonisolated var wrappedValue: T { get set }
    nonisolated var binding: Binding<T> { get }
    nonisolated func callAsFunction() -> T
}

@dynamicMemberLookup
@propertyWrapper
public final class ObservedValue<T: Sendable>: ObservedValueProtocol {
    public nonisolated let publisher: AtomicValueSubject<T>
    @MainActor private var ownerPublisher: ObservableObjectPublisher?
    
    public nonisolated var wrappedValue: T {
        get { publisher.wrappedValue }
        set { publisher.wrappedValue = newValue }
    }
    
    public init(_ value: T, owner: (any ObservableObject)? = nil) {
        publisher = .init(value)
        publisher.sinkMain(retained: publisher) { [weak self] _ in
            self?.objectWillChange.send()
            self?.ownerPublisher?.send()
        }
    }
    
    public var binding: Binding<T> {
        .init(get: { self.wrappedValue }, set: { self.wrappedValue = $0 })
    }
    
    public func republish(_ owner: any ObservableObject ) {
        Task { @MainActor in ownerPublisher = owner.objectWillChange as? ObservableObjectPublisher }
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        publisher.mutate(mutation)
    }
    
    public nonisolated func callAsFunction() -> T { wrappedValue }
    
    public subscript<S>(dynamicMember keyPath: KeyPath<T, S>) -> S {
        publisher.wrappedValue[keyPath: keyPath]
    }
    
    public subscript<S>(dynamicMember keyPath: WritableKeyPath<T, S>) -> S {
        get { publisher.wrappedValue[keyPath: keyPath] }
        set { publisher.wrappedValue[keyPath: keyPath] = newValue }
    }
    
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
        mutate { $0 = UserDefaults.load(key: key, storage: storage) ?? defaultValue }
        publisher.sink { UserDefaults.store($0, key: key, storage: storage) }.retained(by: self)
    }
}

public extension ObservedValue {
    
    @discardableResult
    func didChange(retained: AnyObject? = nil, _ closure: @Sendable @escaping (_ old: T, _ new: T) async -> ()) -> AnyCancellable {
        let result = publisher.scan((Optional<T>.none, self())) { ($0.1, current: $1) }.sinkSendable { value in
            await closure(value.0!, value.1)
        }
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
}
