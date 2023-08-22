//
//  RePublished.swift
//  
//
//  Created by Ilya Kuznetsov on 22/08/2023.
//

import Foundation
import Combine

@MainActor
@propertyWrapper
public final class RePublished<Value: ObservableObject> {
    
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, RePublished>) -> Value {
        get {
            if instance[keyPath: storageKeyPath].observer == nil {
                instance[keyPath: storageKeyPath].setupObserver(instance)
            }
            return instance[keyPath: storageKeyPath].value
        }
        set {
            instance[keyPath: storageKeyPath].value = newValue
            instance[keyPath: storageKeyPath].setupObserver(instance)
        }
    }
    
    private func setupObserver<T: ObservableObject>(_ instance: T) {
        observer = value.objectWillChange.sink { [unowned instance] _ in
            (instance.objectWillChange as any Publisher as? ObservableObjectPublisher)?.send()
        }
    }

    private var observer: AnyCancellable?
    
    @available(*, unavailable,
        message: "This property wrapper can only be applied to classes"
    )
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }
    
    private var value: Value
    
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    //public var projectedValue: AnyPublisher<Value, Never> {
    //    wrappedValue.objectWillChange
    //}
}
