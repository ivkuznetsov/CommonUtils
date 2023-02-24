//
//  RWAtomic.swift
//

import Foundation
import Combine

public extension DispatchQueue {
    
    static func performOnMain(_ closure: ()->()) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.sync {
                closure()
            }
        }
    }
}

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
            
            DispatchQueue.performOnMain {
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

@propertyWrapper
public class RWAtomic<T> {
    private var value: T
    private let lock = RWLock()
    
    public init(wrappedValue value: T) {
        self.value = value
    }

    public var wrappedValue: T {
        get { lock.read { value } }
        set { lock.write { value = newValue } }
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        lock.write {
            mutation(&value)
        }
    }
    
    public func locking<R>(_ block: (T) throws -> R) rethrows -> R {
        try lock.write {
            try block(value)
        }
    }
}

public extension NSLock {
    
    func locking<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
    
    func locking<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
    
    func locking(_ block: () -> ()) {
        lock()
        block()
        unlock()
    }
}

public class RWLock {
    private var lock: pthread_rwlock_t
    
    public init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }
    
    public func read<T>(_ closure: () throws -> T) rethrows -> T {
        pthread_rwlock_rdlock(&lock)
        let result = try closure()
        pthread_rwlock_unlock(&lock)
        return result
    }
    
    public func write<T>(_ closure: () throws -> T) rethrows -> T {
        pthread_rwlock_wrlock(&lock)
        let result = try closure()
        pthread_rwlock_unlock(&lock)
        return result
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
}
