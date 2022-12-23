//
//  UITableView+Reloading.swift
//

#if os(iOS)
import UIKit

public typealias TableView = UITableView
public typealias TableViewAnimation = UITableView.RowAnimation

#else
import AppKit

public typealias TableView = NSTableView
public typealias TableViewAnimation = NSTableView.AnimationOptions

#endif

public extension TableView {
    
    func reload(oldData: [AnyHashable],
                newData: [AnyHashable],
                deferred: ()->(),
                updateObjects: ()->(),
                addAnimation: TableViewAnimation,
                deleteAnimation: TableViewAnimation,
                animated: Bool) {
        
        let diff = newData.diff(oldData: oldData)
        
        func update() {
            beginUpdates()
            updateObjects()
            
            if diff.delete.count > 0 {
                #if os(iOS)
                deleteRows(at: Array(diff.delete), with: deleteAnimation)
                #else
                removeRows(at: IndexSet(diff.delete.map { $0.item }), withAnimation: deleteAnimation)
                #endif
            }
            if diff.add.count > 0 {
                #if os(iOS)
                insertRows(at: Array(diff.add), with: addAnimation)
                #else
                insertRows(at: IndexSet(diff.add.map { $0.item }), withAnimation: addAnimation)
                #endif
            }
            if diff.move.count > 0 {
                diff.move.forEach { couple in
                    #if os(iOS)
                    moveRow(at: couple.from, to: couple.to)
                    #else
                    moveRow(at: couple.from.item, to: couple.to.item)
                    #endif
                }
            }
            
            deferred()
            endUpdates()
        }
        
        if animated && window != nil && oldData.count > 0 && newData.count > 0 {
            update()
        } else {
            #if os(iOS)
            UIView.performWithoutAnimation { update() }
            #else
            NSAnimationContext.runAnimationGroup {
                $0.duration = 0
                update()
            }
            #endif
        }
    }
}
