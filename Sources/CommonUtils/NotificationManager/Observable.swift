//
//  Observable.swift
//

import Foundation

public protocol Observable: AnyObject {
    
    static func notificationName() -> String
    
    func observe(_ observer: AnyObject, closure: @escaping (AppNotification?)->())
    
    static func observe(_ observer: AnyObject, closure: @escaping (AppNotification?)->())
    
    // removing observer is not necessary, it will be removed after object gets deallocated
    static func cancelObserving(_ observer: AnyObject)
    
    static func post(_ notification: AppNotification?)
    func post(_ notification: AppNotification?)
}

public extension Observable {
    
    static func notificationName() -> String {
        return String(describing: self)
    }
    
    func observe(_ observer: AnyObject, closure: @escaping (AppNotification?)->()) {
        type(of: self).observe(observer) { [unowned self] (notification) in
            if notification == nil || notification!.object == nil || notification!.object! === self {
                closure(notification)
            }
        }
    }
    
    static func observe(_ observer: AnyObject, closure: @escaping (AppNotification?)->()) {
        NotificationManager.shared.add(observer: observer, closure: closure, names: [notificationName()])
    }
    
    static func cancelObserving(_ observer: AnyObject) {
        NotificationManager.shared.remove(observer: observer, names: [notificationName()])
    }
    
    static func post(_ notification: AppNotification?) {
        NotificationManager.shared.postNotification(names: [notificationName()], notification: notification)
    }
    
    func post(_ notification: AppNotification?) {
        let notification = notification ?? AppNotification()
        notification.object = self
        type(of: self).post(notification)
    }
}
