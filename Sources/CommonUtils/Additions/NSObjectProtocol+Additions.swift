//
//  NSObjectProtocol.swift
//  
//
//  Created by Ilya Kuznetsov on 24/12/2022.
//

import Foundation
import Combine

fileprivate var retainKey: Void?

fileprivate class RetainWrapper {
    var objects: [Any] = []
}

public protocol Retainable {
    
    func retained(by object: AnyObject)
}

extension Retainable {
    
    public func retained(by object: AnyObject) {
        let wrapper = objc_getAssociatedObject(object, &retainKey) as? RetainWrapper ?? RetainWrapper()
        wrapper.objects.append(self)
        objc_setAssociatedObject(object, &retainKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

extension NSObject: Retainable { }

extension AnyCancellable: Retainable { }
