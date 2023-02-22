//
//  RWAtomic.swift
//

import Foundation

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

/// for use with @Published
public struct PAtomic<T> {
    
    private var internalValue: T
    private let lock = RWLock()
    
    public init(_ value: T) {
        internalValue = value
    }
    
    public var value: T {
        get {
            lock.sync { internalValue }
        }
        set {
            lock.sync {
                DispatchQueue.performOnMain {
                    internalValue = newValue
                }
            }
        }
    }
    
    public mutating func mutate(_ mutation: (inout T) -> ()) {
        lock.sync {
            DispatchQueue.performOnMain {
                mutation(&internalValue)
            }
        }
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
        get { lock.sync { value } }
        set { lock.sync { value = newValue } }
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        lock.sync {
            mutation(&value)
        }
    }
    
    public func locking<R>(_ block: (T) throws -> R) rethrows -> R {
        try lock.sync {
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
    
    public func sync<T>(_ closure: () throws -> T) rethrows -> T {
        pthread_rwlock_wrlock(&lock)
        let result = try closure()
        pthread_rwlock_unlock(&lock)
        return result
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
}
