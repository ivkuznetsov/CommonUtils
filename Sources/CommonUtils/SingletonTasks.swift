//
//  SingletonTasks.swift
//

import Foundation

public protocol TasksProtocol {
    
    var defaultQueue: String { get }
    
    func internalRun<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success
}

extension TasksProtocol {
    
    public func run(_ block: @Sendable @escaping () async -> ()) async -> () {
        await run(key: defaultQueue, block)
    }
    
    public func runIsolated(_ block: @escaping @isolated(any) () async -> ()) async -> () {
        await run(key: defaultQueue, { await block() })
    }
    
    public func run<Owner: Actor>(isolated: Owner, _ block: @escaping (isolated Owner) async -> ()) async -> () {
        await run(key: defaultQueue) { [weak isolated] in
            if let isolated { await block(isolated) }
        }
    }
    
    public func run<Success>(_ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await run(key: defaultQueue, block)
    }
    
    public func runIsolated<Success>(_ block: @escaping @isolated(any) () async throws -> Success) async throws -> Success {
        try await run(key: defaultQueue, { try await block() })
    }
    
    public func run<Owner: Actor, Success>(isolated: Owner, _ block: @escaping (isolated Owner) async throws -> Success) async throws -> Success {
        try await run(key: defaultQueue) { [weak isolated] in
            if let isolated { try await block(isolated) } else { throw CancellationError() }
        }
    }
    
    public func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await internalRun(key: key, block)
    }
    
    public func runIsolated<Success>(key: String, _ block: @escaping @isolated(any) () async throws -> Success) async throws -> Success {
        try await internalRun(key: key, { try await block() })
    }
    
    public func run<Owner: Actor, Success>(key: String, isolated: Owner, _ block: @Sendable @escaping (isolated Owner) async throws -> Success) async throws -> Success {
        try await internalRun(key: key) { [weak isolated] in
            if let isolated { try await block(isolated) } else { throw CancellationError() }
        }
    }
    
    public func run(key: String, _ block: @Sendable @escaping () async -> ()) async -> () {
        try? await internalRun(key: key, block)
    }
    
    public func runIsolated(key: String, _ block: @escaping @isolated(any) () async -> ()) async -> () {
        try? await internalRun(key: key, { await block() })
    }
    
    public func run<Owner: Actor>(key: String, isolated: Owner, _ block: @Sendable @escaping (isolated Owner) async -> ()) async -> () {
        try? await internalRun(key: key) { [weak isolated] in
            if let isolated { await block(isolated) } else { throw CancellationError() }
        }
    }
    
    nonisolated public func run<Success>(_ block: @Sendable @escaping () async throws -> Success) {
        Task { try? await run(block) }
    }
    
    nonisolated public func runIsolated<Success>(_ block: @escaping @isolated(any) () async throws -> Success) {
        Task { try? await run({ try await block() }) }
    }
    
    nonisolated public func run<Owner: Actor, Success>(isolated: Owner, _ block: @Sendable @escaping (isolated Owner) async -> Success) {
        Task {
            try? await run({ [weak isolated] in
                if let isolated { await block(isolated) } else { throw CancellationError() }
            })
        }
    }
}

public actor SerialTasks: TasksProtocol {
    
    public let defaultQueue = UUID().uuidString
    private var currentTasks: [String: (id: UUID, task: Task<Any, Error>)] = [:]
    
    public init() {}
    
    public func internalRun<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        let id = UUID()
        
        return try await withTaskCancellationHandler {
            while let (_, task) = currentTasks[key] {
                _ = await task.result
            }
            try Task.checkCancellation()
            
            currentTasks[key] = (id, Task.detached {
                return try await block() as Any
            })
            
            do {
                let result = try await currentTasks[key]!.task.value as! Success
                currentTasks[key] = nil
                return result
            } catch {
                currentTasks[key] = nil
                throw error
            }
        } onCancel: {
            Task { await cancel(key: key, id: id) }
        }
    }
    
    public func cancel(key: String, id: UUID? = nil) {
        if let task = currentTasks[key] {
            if id == nil || task.id == id {
                task.task.cancel()
            }
        }
    }
}

public actor OrderedSerialTasks: TasksProtocol {
    
    public let defaultQueue = UUID().uuidString
    private var currentTasks: [String: (id: UUID, task: Task<Any, Error>)] = [:]
    
    public init() {}
    
    public func internalRun<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        let id = UUID()
        let previousTask = currentTasks[key]?.task
        let task = Task.detached {
            if let previousTask {
                _ = await previousTask.result
            }
            try Task.checkCancellation()
            return try await block() as Any
        }
        
        currentTasks[key] = (id, task)
        
        return try await withTaskCancellationHandler {
            do {
                let result = try await task.value as! Success
                cleanup(key: key, id: id)
                return result
            } catch {
                cleanup(key: key, id: id)
                throw error
            }
        } onCancel: {
            task.cancel()
        }
    }
    
    private func cleanup(key: String, id: UUID) {
        if currentTasks[key]?.id == id {
            currentTasks[key] = nil
        }
    }
    
    public func cancel(key: String, id: UUID? = nil) {
        if let task = currentTasks[key] {
            if id == nil || task.id == id {
                task.task.cancel()
            }
        }
    }
}

public actor SingletonTasks {
    private static let shared = SingletonTasks()
    
    public init() { }
    
    private var currentTasks: [String: Task<Any, Error>] = [:]

    public func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        if let currentTask = currentTasks[key] {
            return try await currentTask.value as! Success
        }
        let task = Task { try await block() as Any }
        currentTasks[key] = task
        do {
            let result = try await task.value as! Success
            currentTasks[key] = nil
            return result
        } catch {
            currentTasks[key] = nil
            throw error
        }
    }
    
    public func cancel(key: String) {
        currentTasks[key]?.cancel()
        currentTasks[key] = nil
    }
    
    public static func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await shared.run(key: key, block)
    }
    
    public static func cancel(key: String) async {
        await shared.cancel(key: key)
    }
}

public actor ExclusiveTasks: TasksProtocol {
    
    public let defaultQueue = UUID().uuidString
    private var currentTasks: [String: Task<Any, Error>] = [:]

    public init() {}
    
    public func internalRun<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        currentTasks[key]?.cancel()
        
        let task = Task { try await block() as Any }
        currentTasks[key] = task
        let result = try await task.value as! Success
        currentTasks[key] = nil
        return result
    }
}

public actor ThrottledTasks {
    
    private var isProcessing = false
    private var pendingTask: (@isolated(any) () async -> ())?

    public init() {}
    
    public func run(_ block: @isolated(any) @escaping () async -> ()) async {
        pendingTask = block
        guard !isProcessing else { return }
        
        isProcessing = true
        while let task = pendingTask {
            pendingTask = nil
            await task()
        }
        isProcessing = false
    }
    
    public func run<Owner: Actor>(isolated: Owner, _ block: @escaping (isolated Owner) async -> ()) async {
        await run { [weak isolated] in
            if let isolated {
                await block(isolated)
            }
        }
    }
}
