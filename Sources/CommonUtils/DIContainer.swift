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
    
    public init() {}
}

public final class DIContainer {
    
    fileprivate static let current = DIContainer()
    
    @RWAtomic private var dict: [Int:Any] = [:]
    
    public static func register<Service>(_ key: DependencyKey<Service>, _ make: ()->Service) {
        let service = make()
        current._dict.mutate {
            $0[key.hashValue] = ObservableObjectWrapper(service)
        }
    }
    
    public static func register<Service>(_ key: DependencyKey<Service>, _ service: Service) {
        register(key, { service })
    }
    
    public static func resolve<Service>(_ key: DependencyKey<Service>) -> ObservableObjectWrapper<Service> {
        current.dict[key.hashValue] as! ObservableObjectWrapper<Service>
    }
}

@propertyWrapper
public struct DependencyPath<Service> { // size = 8
    
    public let wrappedValue: Service
    
    public init<Container>(_ key: DependencyKey<Container>, _ keyPath: KeyPath<Container, Service>) {
        wrappedValue = DIContainer.resolve(key).observed[keyPath: keyPath]
    }
}

@propertyWrapper
public struct Dependency<Service> { // size = 0
    
    public var wrappedValue: Service { DIContainer.resolve(.init()).observed }
    
    public init(_ key: DependencyKey<Service>) {
        _ = wrappedValue // validate existance
    }
}

@propertyWrapper
public struct ObservedDependency<Service>: DynamicProperty { // size = 17
    
    @StateObject private var wrapper: ObservableObjectWrapper<Service>
    
    public var wrappedValue: Service { wrapper.observed }
    
    public init(_ key: DependencyKey<Service>) {
        _wrapper = .init(wrappedValue: DIContainer.resolve(key))
    }
    
    public init<Container>(_ key: DependencyKey<Container>, _ keyPath: KeyPath<Container, Service>) {
        _wrapper = .init(wrappedValue: .init(DIContainer.resolve(key).observed[keyPath: keyPath]))
    }
    
    public var projectedValue: Binding<Service> { $wrapper.observed }
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
        value = DIContainer.resolve(key).observed[keyPath: keyPath]
    }
    
    public init(_ key: DependencyKey<Service>) {
        value = DIContainer.resolve(key).observed
    }
}

public final class ObservableObjectWrapper<Value>: ObservableObject {
    
    @Published public var observed: Value
    
    public init(_ observable: Value) {
        self.observed = observable
        
        if let observable = observable as? any ObservableObject {
            (observable.objectWillChange as any Publisher as? ObservableObjectPublisher)?.sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
            }).retained(by: self)
        }
    }
}
