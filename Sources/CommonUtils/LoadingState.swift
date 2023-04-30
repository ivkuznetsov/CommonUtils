//
//  LoadingState.swift
//  

import Foundation

public final class LoadingState: ObservableObject {
    public enum Value: Equatable {
        case stop
        case loading
        case failed(Error)
        
        public static func == (lhs: LoadingState.Value, rhs: LoadingState.Value) -> Bool {
            switch (lhs, rhs) {
            case (.stop, .stop): return true
            case (.loading, .loading): return true
            case (.failed(let error1), .failed(let error2)): return error1.localizedDescription == error2.localizedDescription
            default: return false
            }
        }
    }
    
    @Published public var value: Value = .stop
    
    public init() { }
    
    public func reset() {
        value = .stop
    }
    
    public func process(_ error: Error) {
        if error.isCancelled {
            value = .stop
        } else {
            value = .failed(error)
        }
    }
}
