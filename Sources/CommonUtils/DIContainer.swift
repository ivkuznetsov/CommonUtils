//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 29/03/2023.
//

import Foundation
import SwiftUI
import Combine

public struct DependencyKey<Value>: Hashable {
    private let id = ObjectIdentifier(Value.self)
    private let key: Int?
    
    public init(key: String? = nil) {
        self.key = key?.hashValue
    }
}

public final class DIContainer {
    
    fileprivate static let current = DIContainer()
    
    @RWAtomic private var dict: [Int:Any] = [:]
    
    public static func register<Service>(_ key: DependencyKey<Service>, _ make: ()->Service) {
        let service = make()
        current._dict.mutate {
            $0[key.hashValue] = service
        }
    }
    
    public static func register<Service>(_ key: DependencyKey<Service>, _ service: Service) {
        register(key, { service })
    }
    
    public static func resolve<Service>(_ key: DependencyKey<Service>) -> Service {
        current.dict[key.hashValue] as! Service
    }
}

@propertyWrapper
public struct Dependency<Service> {
    
    public let wrappedValue: Service
    
    public init<Container>(_ key: DependencyKey<Container>, _ keyPath: KeyPath<Container, Service>) {
        wrappedValue = DIContainer.resolve(key)[keyPath: keyPath]
    }
    
    public init(_ key: DependencyKey<Service>) {
        wrappedValue = DIContainer.resolve(key)
    }
}

@propertyWrapper
public struct ObservedDependency<Service>: DynamicProperty {
    
    @ObservedObject private var wrapper: ObservableObjectWrapper<Service>
    
    public var wrappedValue: Service { wrapper.observable }
    
    public init<Container>(_ key: DependencyKey<Container>, _ keyPath: KeyPath<Container, Service>) {
        wrapper = .init(DIContainer.resolve(key)[keyPath: keyPath])
    }
    
    public init(_ key: DependencyKey<Service>) {
        wrapper = .init(DIContainer.resolve(key))
    }
    
    public var projectedValue: Binding<Service> { $wrapper.observable }
}

@propertyWrapper
public final class RePublishDependency<Service> {
    
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Service>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, RePublishDependency>) -> Service {
        get {
            if instance[keyPath: storageKeyPath].observer == nil {
                instance[keyPath: storageKeyPath].setupObserver(instance)
            }
            return instance[keyPath: storageKeyPath].value
        }
        set { }
    }
    
    private func setupObserver<T: ObservableObject>(_ instance: T) {
        if let observable = value as? any ObservableObject {
            observer = (observable.objectWillChange as any Publisher as? ObservableObjectPublisher)?.sink(receiveValue: { [weak instance] in
                (instance?.objectWillChange as? any Publisher as? ObservableObjectPublisher)?.send()
            })
        } else {
            observer = nil
        }
    }

    private var observer: AnyCancellable?
    
    @available(*, unavailable,
        message: "This property wrapper can only be applied to classes"
    )
    public var wrappedValue: Service {
        get { fatalError() }
        set { fatalError() }
    }
    
    private var value: Service
    
    public init<Container>(_ key: DependencyKey<Container>, _ keyPath: KeyPath<Container, Service>) {
        value = DIContainer.resolve(key)[keyPath: keyPath]
    }
    
    public init(_ key: DependencyKey<Service>) {
        value = DIContainer.resolve(key)
    }
}

public final class ObservableObjectWrapper<Value>: ObservableObject {
    
    @Published public var observable: Value
    
    public init(_ observable: Value) {
        self.observable = observable
        
        if let observable = observable as? any ObservableObject {
            (observable.objectWillChange as any Publisher as? ObservableObjectPublisher)?.sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            }).retained(by: self)
        }
    }
}
