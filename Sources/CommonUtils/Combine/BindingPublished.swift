//
//  BindingPublished.swift
//  
//
//  Created by Ilya Kuznetsov on 22/08/2023.
//

import Foundation
import SwiftUI

@propertyWrapper
public struct BindingPublished<Value>: DynamicProperty {
    
    public final class State: ObservableObject {
        let binding: Binding<Value>
        @Published public var value: Value {
            didSet { binding.wrappedValue = value }
        }
        
        init(binding: Binding<Value>) {
            self.binding = binding
            self.value = binding.wrappedValue
        }
    }
    
    @StateObject public var state: State
    
    public var wrappedValue: Value {
        get { state.value }
        nonmutating set { state.value = newValue }
    }
    
    public init(_ binding: Binding<Value>) {
        _state = .init(wrappedValue: .init(binding: binding))
    }
    
    public var projectedValue: Binding<Value> { .init(get: { wrappedValue }, set: { wrappedValue = $0 }) }
}
