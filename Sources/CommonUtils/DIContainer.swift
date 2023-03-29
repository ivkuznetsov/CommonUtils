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
    private let id = String(describing: Value.self)
    private var key: String?
    
    public init(key: String? = nil) {
        self.key = key
    }
}

public struct DIContainer {
    
    @RWAtomic fileprivate static var current = DIContainer()
    
    fileprivate var dict: [Int:Any] = [:]
    
    public static func register<Service>(_ key: DependencyKey<Service>, _ make: ()->Service) {
        _current.mutate {
            $0.dict[key.hashValue] = make()
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

public class ObservableObjectWrapper<Value>: ObservableObject {
    
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
