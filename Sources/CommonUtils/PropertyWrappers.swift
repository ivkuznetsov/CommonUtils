//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 22/09/2023.
//

import Foundation
import SwiftUI
import CoreData
import Combine

public enum DB {
    
    @propertyWrapper
    public final class RePublished<ManagedObject: NSManagedObject> {
        
        public static subscript<T: ObservableObject>(
            _enclosingInstance instance: T,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, ManagedObject?>,
            storage storageKeyPath: ReferenceWritableKeyPath<T, RePublished>) -> ManagedObject? {
            get {
                if instance[keyPath: storageKeyPath].observer == nil {
                    instance[keyPath: storageKeyPath].setupObserver(instance)
                }
                return instance[keyPath: storageKeyPath].value.wrappedValue
            }
            set {
                instance[keyPath: storageKeyPath].value.wrappedValue = newValue
                instance[keyPath: storageKeyPath].setupObserver(instance)
            }
        }
        
        private func setupObserver<T: ObservableObject>(_ instance: T) {
            observer = value.objectWillChange.sink { [unowned instance] _ in
                (instance.objectWillChange as any Publisher as? ObservableObjectPublisher)?.send()
            }
        }

        private var observer: AnyCancellable?
        
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: ManagedObject? {
            get { fatalError() }
            set { fatalError() }
        }
        
        private let value = Object<ManagedObject>(wrappedValue: nil)
        
        public init(wrappedValue: ManagedObject? = nil) {
            value.wrappedValue = wrappedValue
        }
    }
    
    // For use in SwiftUI views
    @propertyWrapper 
    public struct Observed<ManagedObject: NSManagedObject>: DynamicProperty {
        
        private final class Wrapper {
            var object: ManagedObject?
        }
        
        @StateObject private var object: Object<ManagedObject>
        private let currentObject = Wrapper()
        
        public var wrappedValue: ManagedObject? {
            get { currentObject.object }
            nonmutating set {
                currentObject.object = newValue
                object.wrappedValue = newValue
            }
        }
        
        public init(wrappedValue: ManagedObject?) {
            currentObject.object = wrappedValue
            _object = .init(wrappedValue: .init(wrappedValue: wrappedValue))
        }
        
        public func update() {
            if object.value == nil, let object = currentObject.object, object.managedObjectContext == nil || object.isDeleted {
                currentObject.object = nil
            } else {
                object.value = currentObject.object
            }
        }
    }
    
    @propertyWrapper
    public final class Object<ManagedObject: NSManagedObject>: ObservableObject {
        
        private var observer: AnyCancellable?
        fileprivate var value: ManagedObject?
        
        public var wrappedValue: ManagedObject? {
            get { value }
            set {
                if value != newValue {
                    objectWillChange.send()
                    value = newValue
                    setupObserver()
                }
            }
        }
        
        public init(wrappedValue: ManagedObject?) {
            self.wrappedValue = wrappedValue
            setupObserver()
        }
        
        private func setupObserver() {
            observer = wrappedValue?.objectWillChange.sink { [weak self] in
                guard let wSelf = self else { return }
                
                wSelf.objectWillChange.send()
                if let object = wSelf.wrappedValue, object.managedObjectContext == nil || object.isDeleted {
                    wSelf.wrappedValue = nil
                }
            }
        }
    }
}



