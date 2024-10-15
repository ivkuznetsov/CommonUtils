//
//  Atomic.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 15/10/2024.
//

@dynamicMemberLookup
@propertyWrapper
public final class Atomic<T>: @unchecked Sendable {
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
    
    public func mutate(_ mutation: (inout T) -> ()) {
        lock.write { mutation(&value) }
    }
    
    public func locking<R>(_ block: (T) throws -> R) rethrows -> R {
        try lock.write {
            try block(value)
        }
    }
    
    public subscript<S>(dynamicMember keyPath: KeyPath<T, S>) -> S {
        lock.read { value[keyPath: keyPath] }
    }
    
    public subscript<S>(dynamicMember keyPath: WritableKeyPath<T, S>) -> S {
        get { lock.read { value[keyPath: keyPath] } }
        set { lock.write { value[keyPath: keyPath] = newValue } }
    }
    
    public nonisolated func callAsFunction() -> T { wrappedValue }
}
