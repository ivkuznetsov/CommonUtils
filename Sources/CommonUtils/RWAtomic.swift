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

    public init(_ value: T) {
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
    
    public subscript<S>(dynamicMember keyPath: WritableKeyPath<T, S>) -> S {
        get { lock.read { value[keyPath: keyPath] } }
        set { lock.write { value[keyPath: keyPath] = newValue } }
    }
}

extension RWAtomic: Sendable where T: Sendable { }

public extension NSLock {
    
    func locking<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        do {
            let result = try block()
            unlock()
            return result
        } catch {
            unlock()
            throw error
        }
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

public final class RWLock: @unchecked Sendable {
    private var lock: pthread_rwlock_t
    
    public init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }
    
    public func read<T>(_ closure: () throws -> T) rethrows -> T {
        pthread_rwlock_rdlock(&lock)
        do {
            let result = try closure()
            pthread_rwlock_unlock(&lock)
            return result
        } catch {
            pthread_rwlock_unlock(&lock)
            throw error
        }
    }
    
    public func write<T>(_ closure: () throws -> T) rethrows -> T {
        pthread_rwlock_wrlock(&lock)
        do {
            let result = try closure()
            pthread_rwlock_unlock(&lock)
            return result
        } catch {
            pthread_rwlock_unlock(&lock)
            throw error
        }
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
}
