//
//  DI.swift
//  
//
//  Created by Ilya Kuznetsov on 29/03/2023.
//

import Foundation
import SwiftUI
import Combine

///An example of using the dependency injection container.
///Define keys:
///
///     extension DI {
///         static let network = Key<any Network>()
///         static let dataManager = Key<any DataManager>()
///         static let settings = Key<any Settings>()
///     }
///
///Register your serivces:
///
///     extension DI.Container {
///         static func setup() {
///             register(DI.network, NetworkImp())
///             register(DI.dataManager, DataManagerImp())
///             register(DI.settings, SettingsImp())
///         }
///     }
///
///Use in class:
///
///     class SomeStateObject: ObservableObject {
///         @DI.Static(DI.network) var network
///         @DI.StaticPath(DI.network, \.tokenUpdater) var tokenUpdater
///         @DI.RePublished(DI.settings) var settings
///     }
///
///Use in view:
///
///     struct SomeView: View {
///         @DI.Observed(DI.dataManager) var data
///     }
    
public enum DI {

    ///A key for storing services in DI.Container
    public struct Key<Value>: Hashable {
        private let id = ObjectIdentifier(Value.self)
        
        public init() {}
    }
    
    ///A singletone container for services. Registering a new service replaces the old one with the same key.
    public final class Container {
        
        fileprivate static let current = Container()
        
        @RWAtomic private var dict: [Int:Any] = [:]
        
        public static func register<Service>(_ key: Key<Service>, _ make: ()->Service) {
            let service = make()
            current._dict.mutate {
                $0[key.hashValue] = ObservableObjectWrapper(service)
            }
        }
        
        public static func register<Service>(_ key: Key<Service>, _ service: Service) {
            register(key, { service })
        }
        
        public static func resolve<Service>(_ key: Key<Service>) -> ObservableObjectWrapper<Service> {
            current.dict[key.hashValue] as! ObservableObjectWrapper<Service>
        }
    }
    
    ///Property wrapper with a reference to a service in DI.Container.
    ///This wrapper doesn't increaze the size of a struct.
    @propertyWrapper
    public struct Static<Service> { // size = 0
        
        public var wrappedValue: Service { Container.resolve(.init()).observed }
        
        public init(_ key: Key<Service>) {
            _ = wrappedValue // validate existance
        }
    }
    
    ///Property wrapper with a reference to a sub-service of some service in DI.Container defined by a keyPath.
    ///The size is 8 bytes.
    @propertyWrapper
    public struct StaticPath<Service> {
        
        public let wrappedValue: Service
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            wrappedValue = Container.resolve(key).observed[keyPath: keyPath]
        }
    }
    
    ///Property wrapper with a reference to an 'ObservableObject' service in DI.Container.
    ///It should be used only in SwiftUI view. The change in service triggers the view update.
    ///The sub-service can be referenced by using a KeyPath.
    ///The size is 17 bytes.
    @propertyWrapper
    public struct Observed<Service>: DynamicProperty {
        
        @StateObject private var wrapper: ObservableObjectWrapper<Service>
        
        public var wrappedValue: Service { wrapper.observed }
        
        public init(_ key: Key<Service>) {
            _wrapper = .init(wrappedValue: Container.resolve(key))
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            _wrapper = .init(wrappedValue: .init(Container.resolve(key).observed[keyPath: keyPath]))
        }
        
        public var projectedValue: Binding<Service> { $wrapper.observed }
    }
    
    ///Property wrapper with a refernce to an 'ObservableObject' service in DI.Container.
    ///It should be used in another 'ObservableObject'. An update of the service triggers objectWillChange of enoclosing instance.
    ///The sub-service can be referenced by using a KeyPath.
    @propertyWrapper
    public final class RePublished<Service> {
        
        public static subscript<T: ObservableObject>(
            _enclosingInstance instance: T,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Service>,
            storage storageKeyPath: ReferenceWritableKeyPath<T, RePublished>) -> Service {
            get {
                if instance[keyPath: storageKeyPath].observer == nil {
                    instance[keyPath: storageKeyPath].setupObserver(instance)
                }
                return instance[keyPath: storageKeyPath].value
            }
            set { }
        }
        
        private func setupObserver<T: ObservableObject>(_ instance: T) {
            observer = (value as? any ObservableObject)?.sink { [weak instance] in
                (instance?.objectWillChange as? any Publisher as? ObservableObjectPublisher)?.send()
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
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            value = Container.resolve(key).observed[keyPath: keyPath]
        }
        
        public init(_ key: Key<Service>) {
            value = Container.resolve(key).observed
        }
    }
}

///ObservableObject wrapper with type erased input. An update of the contained instance triggers objectWillChange of this wrapper.
///This is convenient for using protocol types.
public final class ObservableObjectWrapper<Value>: ObservableObject {
    
    @AtomicPublished public var observed: Value
    
    public init(_ observable: Value) {
        self.observed = observable
        
        (observable as? any ObservableObject)?.sink(retained: self) { [weak self] in
            self?.objectWillChange.send()
        }
    }
}
