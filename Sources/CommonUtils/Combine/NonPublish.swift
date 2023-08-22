//
//  NonPublish.swift
//  
//
//  Created by Ilya Kuznetsov on 22/08/2023.
//

import Foundation
import Combine

@propertyWrapper
public final class NonPublish<T>: ObservableObject {
    
    private var value: T
    
    public init(wrappedValue value: @escaping @autoclosure ()->T) {
        self.value = value()
    }

    public var wrappedValue: T {
        get { value }
        set { value = newValue }
    }
}
