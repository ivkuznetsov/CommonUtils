//
//  RWAtomic.swift
//

import Foundation

@propertyWrapper
public class RWAtomic<T> {
    private var value: T
    private let queue = DispatchQueue(label: "com.rwatomic", attributes: .concurrent)

    public init(wrappedValue value: T) {
        self.value = value
    }

    public var wrappedValue: T {
        get { queue.sync { value } }
        set { queue.async(flags: .barrier) { [weak self] in self?.value = newValue } }
    }
    
    public func mutate(_ mutation: (inout T) -> ()) {
        queue.sync(flags: .barrier) {
            mutation(&value)
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
