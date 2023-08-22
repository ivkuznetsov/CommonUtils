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
    
    @Binding private var binding: Value
    @State private var value: Value
    
    public var wrappedValue: Value {
        get { value }
        nonmutating set {
            value = newValue
            binding = newValue
        }
    }
    
    public init(_ binding: Binding<Value>) {
        _binding = binding
        _value = State(initialValue: binding.wrappedValue)
    }
    
    public var projectedValue: Binding<Value> { $value }
}
