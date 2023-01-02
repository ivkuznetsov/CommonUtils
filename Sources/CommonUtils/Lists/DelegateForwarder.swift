//
//  DelegateForwarder.swift
//  
//
//  Created by Ilya Kuznetsov on 01/01/2023.
//

import Foundation

@objc public class DelegateForwarder: NSObject {
    
    private struct WeakHolder {
        weak var object: AnyObject?
    }
    private var receivers: [WeakHolder] = []
    private var excluding = Set<NSObject>()
    
    func addConforming(_ protocols: [Protocol]) {
        protocols.forEach { class_addProtocol(type(of: self), $0) }
    }
    
    public func add(_ receiver: NSObject) {
        receivers.append(WeakHolder(object: receiver as AnyObject))
    }
    
    override public func responds(to aSelector: Selector!) -> Bool {
        receivers.contains(where: {
            if let object = $0.object as? NSObject, !excluding.contains(object) {
                return object.responds(to: aSelector)
            }
            return false
        })
    }
    
    override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        receivers.first(where: { ($0.object as? NSObject)?.responds(to: aSelector) == true })?.object
    }
    
    func without(_ receiver: NSObject, action: ()->()) {
        excluding.insert(receiver)
        action()
        excluding.remove(receiver)
    }
}
