//
//  SingletonTasks.swift
//  
//
//  Created by Ilya Kuznetsov on 08/01/2023.
//

import Foundation

public actor SingletonTasks {
    private static let shared = SingletonTasks()
    
    private var currentTasks: [String: Task<Any, Error>] = [:]

    private func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        if let currentTask = currentTasks[key] {
            return try await currentTask.value as! Success
        }
        let task = Task { try await block() as Any }
        currentTasks[key] = task
        let result = try await task.value as! Success
        currentTasks[key] = nil
        return result
    }
    
    public static func run<Success>(key: String, _ block: @Sendable @escaping () async throws -> Success) async throws -> Success {
        try await shared.run(key: key, block)
    }
}
