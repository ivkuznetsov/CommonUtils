//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 28/12/2022.
//

import Combine

@propertyWrapper
public class PublishedDidSet<Value> {
    private var val: Value
    private let subject: CurrentValueSubject<Value, Never>

    public init(wrappedValue value: Value) {
        val = value
        subject = CurrentValueSubject(value)
        wrappedValue = value
    }

    public var wrappedValue: Value {
        set {
            val = newValue
            subject.send(val)
        }
        get { val }
    }
    
    public var projectedValue: CurrentValueSubject<Value, Never> {
        get { subject }
    }
}
