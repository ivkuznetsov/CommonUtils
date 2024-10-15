//
//  PublishedStorage.swift
//  
//
//  Created by Ilya Kuznetsov on 01/05/2023.
//

import Foundation
import Combine

public protocol OptionalProtocol {
    
    var isNil: Bool { get }
}

extension Optional : OptionalProtocol {
    
    public var isNil: Bool { self == nil }
}

@propertyWrapper
public struct PublishedStorage<Value: Codable> {
    
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            return UserDefaults.load(key: wrapper.key, storage: wrapper.storage) ?? wrapper.defaultValue
        }
        set {
            let publisher = instance.objectWillChange
            
            DispatchQueue.onMain {
                (publisher as? ObservableObjectPublisher)?.send()
                let wrapper = instance[keyPath: storageKeyPath]
                let changePublisher = wrapper.publisher
                UserDefaults.store(newValue, key: wrapper.key, storage: wrapper.storage)
                changePublisher.send(newValue)
            }
        }
    }

    @available(*, unavailable, message: "@PublishedStorage can only be applied to classes")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    private let key: String
    private let storage: UserDefaults
    private let defaultValue: Value
    private let publisher = PassthroughSubject<Value, Never>()
    
    public init(_ key: String, storage: UserDefaults = .standard, defaultValue: Value) {
        self.key = key
        self.storage = storage
        self.defaultValue = defaultValue
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        publisher.eraseToAnyPublisher()
    }
}
