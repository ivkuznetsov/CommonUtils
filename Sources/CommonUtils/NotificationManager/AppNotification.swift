//
//  AppNotification.swift
//

import Foundation

public struct AppNotification {
    
    public let created: Set<AnyHashable>
    public let updated: Set<AnyHashable>
    public let deleted: Set<AnyHashable>
    public let sender: AnyObject?
    public let userInfo: [AnyHashable : Any]
    @RWAtomic public var object: AnyObject?
    
    public init(created: Set<AnyHashable> = Set(),
                updated: Set<AnyHashable> = Set(),
                deleted: Set<AnyHashable> = Set(),
                sender: AnyObject? = nil,
                object: AnyObject? = nil,
                userIndo: [AnyHashable : Any] = [:]) {
        self.created = created
        self.updated = updated
        self.deleted = deleted
        self.sender = sender
        self.object = object
        self.userInfo = userIndo
    }
}
