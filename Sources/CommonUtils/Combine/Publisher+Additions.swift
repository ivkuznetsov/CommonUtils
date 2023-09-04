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
    func sinkMain(retained: AnyObject? = nil, _ closure: @MainActor @escaping (Output)->()) -> AnyCancellable {
        let result = receive(on: DispatchQueue.main).sink(receiveValue: { value in
            Task { @MainActor in
                closure(value)
            }
        })
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
}

public extension Published.Publisher {
    
    @discardableResult
    func sinkOnMain(retained: AnyObject? = nil, dropFirst: Bool = true, _ closure: @MainActor @escaping (Value)->()) -> AnyCancellable {
        let result = self.dropFirst(dropFirst ? 1 : 0).receive(on: DispatchQueue.main).sink(receiveValue: { value in
            Task { @MainActor in
                closure(value)
            }
        })
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
}

public extension ObservableObject {
    
    @discardableResult
    func sinkOnMain(retained: AnyObject? = nil, _ closure: @MainActor @escaping ()->()) -> AnyCancellable {
        let result =  objectWillChange.receive(on: DispatchQueue.main).sink { _ in
            Task { @MainActor in
                closure()
            }
        }
        
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
    }
    
    @discardableResult
    func sink(retained: AnyObject? = nil, _ closure: @escaping ()->()) -> AnyCancellable {
        let result = objectWillChange.sink { _ in closure() }
        
        if let retained = retained {
            result.retained(by: retained)
        }
        return result
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
