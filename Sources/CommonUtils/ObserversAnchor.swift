//
//  ObserversAnchor.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 11/10/2024.
//

import Combine

@MainActor
public final class Observers {
    
    public var store: [any Cancellable] = []
    
    public nonisolated init() { }
    
    public func update(_ update: (_ store: inout [any Cancellable])->()) {
        update(&store)
    }
}

public extension AnyCancellable {
    
    func store(in observers: Observers) {
        Task { await observers.update { $0.append(self) } }
    }
}
