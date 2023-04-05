//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 28/12/2022.
//

import Combine
import Foundation

@propertyWrapper
public class NonPublish<T>: ObservableObject {
    
    private var value: T
    
    public init(wrappedValue value: @escaping @autoclosure ()->T) {
        self.value = value()
    }

    public var wrappedValue: T {
        get { value }
        set { value = newValue }
    }
}

@propertyWrapper
public class PublishedDidSet<Value> {
    private var val: Value
    private let subject: CurrentValueSubject<Value, Never>

    public init(wrappedValue value: Value) {
        val = value
        subject = CurrentValueSubject(value)
        wrappedValue = value
    }

    public var wrappedValue: Value {
        set {
            val = newValue
            subject.send(val)
        }
        get { val }
    }
    
    public var projectedValue: CurrentValueSubject<Value, Never> {
        get { subject }
    }
}

public extension Publisher where Failure == Never {
    
    @discardableResult
    func sinkOnMain(retained: AnyObject? = nil, dropFirst: Bool = true, _ closure: @escaping (Output)->()) -> AnyCancellable {
        let result = self.dropFirst(dropFirst ? 1 : 0).receive(on: DispatchQueue.main).sink(receiveValue: closure)
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
}

@MainActor
@propertyWrapper
public final class RePublish<Value: ObservableObject> {
    
    public static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, RePublish>) -> Value {
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
