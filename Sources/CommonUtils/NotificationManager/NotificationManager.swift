//
//  NotificationManager.swift
//

import Foundation

private struct Observer: Equatable {
    
    static func ==(lhs: Observer, rhs: Observer) -> Bool {
        return lhs.object === rhs.object && lhs.uid == rhs.uid
    }
    
    weak var object: AnyObject?
    var uid: String
    var closure: (AppNotification?)->()
    
    init(object: AnyObject, closure: @escaping (AppNotification?)->(), uid: String) {
        self.object = object
        self.closure = closure
        self.uid = uid
    }
}

@objc(ATNotificationManager)
open class NotificationManager: NSObject {
    
    @objc public static let shared = NotificationManager()
    
    private var dictionary: [AnyHashable:[Observer]] = [:]
    
    @objc open func add(observer: AnyObject, closure: @escaping (AppNotification?)->(), names: [String]) {
        let uid = UUID().uuidString
        
        for name in names {
            var array = dictionary[name] ?? []
            array.append(Observer(object: observer, closure: closure, uid: uid))
            dictionary[name] = array
        }
    }
    
    @objc open func remove(observer: AnyObject, names: [String]) {
        for name in names {
            dictionary[name] = dictionary[name]?.compactMap { $0.object === observer ? nil : $0 }
        }
    }
    
    private func runOnMainThread(_ closure: @escaping ()->()) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }
    
    @objc open func postNotification(names: [String], notification: AppNotification?) {
        runOnMainThread {
            var postedUpdates: [Observer] = []
            
            for name in names {
                if let array = self.dictionary[name] {
                    for observer in array.reversed() {
                        if observer.object == nil || postedUpdates.contains(observer) {
                            continue
                        }
                        
                        if notification?.sender == nil || notification!.sender! !== observer.object {
                            observer.closure(notification)
                        }
                        
                        postedUpdates.append(observer)
                    }
                    self.dictionary[name] = self.dictionary[name]?.filter({ $0.object != nil })
                }
            }
        }
    }
}
