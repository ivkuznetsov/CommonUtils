//
//  AtomicPublished.swift
//  
//
//  Created by Ilya Kuznetsov on 22/08/2023.
//

import Foundation
import Combine

@propertyWrapper
public struct AtomicPublished<Value> {
    
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            return wrapper.lock.read { wrapper.value }
        }
        set {
            let publisher = instance.objectWillChange
            
            DispatchQueue.onMain {
                (publisher as? ObservableObjectPublisher)?.send()
                let lock = instance[keyPath: storageKeyPath].lock
                let changePublisher = instance[keyPath: storageKeyPath].publisher
                
                lock.write {
                    instance[keyPath: storageKeyPath].value = newValue
                }
                changePublisher.send(newValue)
            }
        }
    }

    @available(*, unavailable, message: "@Published can only be applied to classes")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    private let lock = RWLock()
    private let publisher = PassthroughSubject<Value, Never>()
    
    private var value: Value
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        publisher.eraseToAnyPublisher()
    }
}

extension AtomicPublished: Codable where Value: Codable {
    
    enum CodingKeys: String, CodingKey {
        case value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Value.self, forKey: .value)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
}
