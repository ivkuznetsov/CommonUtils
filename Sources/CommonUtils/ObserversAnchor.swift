//
//  ObserversAnchor.swift
//  CommonUtils
//
//  Created by Ilya Kuznetsov on 11/10/2024.
//

import Combine
import Foundation

@MainActor
public final class Observers {
    
    public var store: [String: any Cancellable] = [:]
    
    public nonisolated init() { }
    
    public func update(_ update: (_ store: inout [String:any Cancellable])->()) {
        update(&store)
    }
}

public extension AnyCancellable {
    
    func store(in observers: Observers, key: String? = nil) {
        Task { await observers.update { $0[key ?? UUID().uuidString] = self } }
    }
}
