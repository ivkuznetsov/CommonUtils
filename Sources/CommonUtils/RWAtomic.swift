//
//  RWAtomic.swift
//

import Foundation

@propertyWrapper
public struct RWAtomic<T> {
    private var value: T
    private let lock = RWLock()
    
    public init(wrappedValue value: T) {
        self.value = value
    }

    public var wrappedValue: T {
        get { lock.read { value } }
        set { lock.write { value = newValue } }
    }
    
    public mutating func mutate(_ mutation: (inout T) -> ()) {
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

public final class RWLock {
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
