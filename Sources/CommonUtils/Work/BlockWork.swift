//
//  BlockWork.swift
//

import Foundation

open class BlockWork<T>: Work<T> {
    
    @RWAtomic private var block: ((BlockWork<T>) throws -> T)?
    
    public init(_ block: @escaping ((BlockWork<T>) throws -> T), progress: WorkProgress = .init()) {
        self.block = block
        super.init(progress: progress)
        addCompletion { [weak self] in
            self?.block = nil
        }
    }
    
    convenience public init(_ block: @escaping (() throws -> T)) {
        self.init() { _ in
            try block()
        }
    }
    
    override open func executeSync() throws -> T {
        if let block = block {
            return try block(self)
        }
        throw RunError.cancelled
    }
}

open class AsyncWork<T>: Work<T> {
    
    @RWAtomic private var block: ((AsyncWork<T>) throws -> ())?
    
    public init(block: @escaping ((AsyncWork<T>) throws -> ()), progress: WorkProgress = .init()) {
        self.block = block
        super.init(progress: progress)
        addCompletion { [weak self] in
            self?.block = nil
        }
    }
    
    override open func execute() {
        if let block = block {
            do {
                try block(self)
            } catch {
                reject(error)
            }
        } else {
            reject(RunError.cancelled)
        }
    }
}
