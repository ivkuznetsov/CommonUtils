//
//  SingletonTasks.swift
//

import Foundation

public actor SerialTasks {
    
    private let defaultQueue = UUID().uuidString
    private var currentTasks: [String: (id: UUID, task: Task<Any, Error>)] = [:]
    
    public init() {}
    
    public func run(_ block: @Sendable @escaping () async -> ()) async -> () {
        await run(key: defaultQueue, block)
    }
    
    public func run<Success>(_ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await run(key: defaultQueue, block)
    }
    
    public func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await internalRun(key: key, block)
    }
        
    public func run(key: String, _ block: @Sendable @escaping () async -> ()) async -> () {
        try? await internalRun(key: key, block)
    }
    
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
    
    nonisolated public func run<Success>(_ block: @Sendable @escaping () async throws -> Success) {
        Task { try await run(block) }
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

public actor ExclusiveTasks {
    
    private var currentTasks: [String: Task<Any, Error>] = [:]

    public init() {}
    
    public func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        currentTasks[key]?.cancel()
        
        let task = Task { try await block() as Any }
        currentTasks[key] = task
        let result = try await task.value as! Success
        currentTasks[key] = nil
        return result
    }
}
