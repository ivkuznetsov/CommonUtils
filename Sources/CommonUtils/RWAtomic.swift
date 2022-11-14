//
//  RWAtomic.swift
//

import Foundation

@propertyWrapper
public class RWAtomic<T> {
    private var value: T
    private var lock = pthread_rwlock_t()
    
    public init(wrappedValue value: T) {
        pthread_rwlock_init(&lock, nil)
        self.value = value
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    public var wrappedValue: T {
        get {
            let result: T
            pthread_rwlock_rdlock(&lock)
            result = value
            pthread_rwlock_unlock(&lock)
            return result
        }
        set {
            pthread_rwlock_wrlock(&lock)
            value = newValue
            pthread_rwlock_unlock(&lock)
        }
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        pthread_rwlock_wrlock(&lock)
        mutation(&value)
        pthread_rwlock_unlock(&lock)
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
