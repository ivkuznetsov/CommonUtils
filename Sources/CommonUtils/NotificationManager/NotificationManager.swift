//
//  NotificationManager.swift
//

import Foundation

public class NotificationManager {
    
    private struct Observer: Hashable {
        
        weak var object: AnyObject?
        let uid: String
        let closure: (AppNotification?)->()
        
        init(object: AnyObject, closure: @escaping (AppNotification?)->(), uid: String) {
            self.object = object
            self.closure = closure
            self.uid = uid
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(uid)
        }
        
        static func ==(lhs: Observer, rhs: Observer) -> Bool { lhs.uid == rhs.uid }
    }
    
    public static let shared = NotificationManager()
    
    @RWAtomic private var observers: [String : [Observer]] = [:]
    
    public func add(_ observer: AnyObject, closure: @escaping (AppNotification?)->(), names: [String]) {
        let uid = UUID().uuidString
        
        _observers.mutate { observers in
            names.forEach {
                var array = observers[$0] ?? []
                array.append(Observer(object: observer, closure: closure, uid: uid))
                observers[$0] = array
            }
        }
    }
    
    public func remove(observer: AnyObject, names: [String]) {
        _observers.mutate { observers in
            names.forEach {
                observers[$0] = observers[$0]?.filter { $0.object !== observer }
            }
        }
    }
    
    public func postNotification(names: [String], notification: AppNotification?) {
        var postedUpdates = Set<Observer>()
        
        names.forEach { name in
            observers[name]?.reversed().forEach { observer in
                guard observer.object != nil && !postedUpdates.contains(observer) else { return }
                
                if let sender = notification?.sender, sender === observer.object {} // already posted
                else {
                    DispatchQueue.onMain {
                        observer.closure(notification)
                    }
                    postedUpdates.insert(observer)
                }
            }
            
            _observers.mutate {
                $0[name] = $0[name]?.filter { $0.object != nil }
            }
        }
    }
}
