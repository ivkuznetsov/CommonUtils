//
//  Publisher+Additions.swift
//  
//
//  Created by Ilya Kuznetsov on 28/12/2022.
//

import Combine
import Foundation
import SwiftUI

public typealias ValuePublisher<T> = PassthroughSubject<T, Never>

public typealias VoidPublisher = PassthroughSubject<Void, Never>

public extension Publisher where Failure == Never {
    
    @discardableResult
    func sinkSendable(retained: AnyObject? = nil, _ closure: @Sendable @escaping (Output) -> ()) -> AnyCancellable {
        let result = sink(receiveValue: { value in
            closure(value)
        })
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sinkSendable(retained: AnyObject? = nil, _ closure: @Sendable @escaping (Output) async -> ()) -> AnyCancellable {
        sinkSendable(retained: retained) { value in Task { await closure(value) } }
    }
    
    @discardableResult
    func sinkIsolated(retained: AnyObject? = nil,
                      _ closure: @escaping @isolated(any) (Output) async -> ()) -> AnyCancellable {
        let result = sink(receiveValue: { value in
            Task { await closure(value) }
        })
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sinkSerialized(retained: AnyObject? = nil, _ closure: @escaping @isolated(any) (Output) async -> ()) -> AnyCancellable {
        let (stream, continuation) = AsyncStream<Output>.makeStream()
        let result = sink { continuation.yield($0) }

        Task {
            for await value in stream {
                await closure(value)
            }
        }

        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sinkThrottled(retained: AnyObject? = nil, _ closure: @escaping @isolated(any) (Output) async -> ()) -> AnyCancellable {
        let tasks = ThrottledTasks()
        return sinkIsolated(retained: retained) { value in
            await tasks.run { await closure(value) }
        }
    }
    
    @discardableResult
    func sinkMain(retained: AnyObject? = nil, _ closure: @MainActor @escaping (Output) async ->()) -> AnyCancellable {
        sinkSendable(retained: retained) { value in Task { await closure(value) } }
    }
}

public extension Published.Publisher {
    
    @discardableResult
    func sinkOnMain(retained: AnyObject? = nil, dropFirst: Bool = true, _ closure: @MainActor @escaping (Value) async ->()) -> AnyCancellable {
        let result = self.dropFirst(dropFirst ? 1 : 0).receive(on: DispatchQueue.main).sink(receiveValue: { value in
            Task { await closure(value) }
        })
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
}

public extension ObservableObject {
    
    @discardableResult
    func sinkOnMain(retained: AnyObject? = nil, _ closure: @MainActor @escaping () async ->()) -> AnyCancellable {
        let result = objectWillChange.receive(on: DispatchQueue.main).sink { _ in
            Task { await closure() }
        }
        
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sink(retained: AnyObject? = nil, _ closure: @Sendable @escaping ()->()) -> AnyCancellable {
        let result = objectWillChange.sink { _ in closure() }
        
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sink(retained: AnyObject? = nil, _ closure: @Sendable @escaping () async ->()) -> AnyCancellable {
        sink(retained: retained) { Task { await closure() } }
    }
    
    @discardableResult
    func sinkIsolated(retained: AnyObject? = nil, _ closure: @escaping @isolated(any) () async ->()) -> AnyCancellable {
        sink(retained: retained) { [closure] in Task { await closure() } }
    }
    
    @discardableResult
    func sinkSerialized(retained: AnyObject? = nil, _ closure: @escaping @isolated(any) () async -> ()) -> AnyCancellable {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let result = sink { continuation.yield() }

        Task {
            for await _ in stream {
                await closure()
            }
        }

        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sinkThrottled(retained: AnyObject? = nil, _ closure: @escaping @isolated(any) () async -> ()) -> AnyCancellable {
        let tasks = ThrottledTasks()
        return sinkIsolated(retained: retained) {
            await tasks.run { await closure() }
        }
    }
}

public extension Publisher {
    
    func map<T>(_ transform: @escaping (Output) async throws -> T) -> Publishers.FlatMap<Future<T, Error>, Publishers.SetFailureType<Self, Error>> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    func map<T>(_ transform: @escaping (Output) async -> T) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    promise(.success(await transform(value)))
                }
            }
        }
    }
}
