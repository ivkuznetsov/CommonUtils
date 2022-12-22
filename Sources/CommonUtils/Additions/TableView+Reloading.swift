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
    
    private func printDuplicates(_ array: [AnyHashable]) {
        var allSet = Set<AnyHashable>()
        
        for object in array {
            if allSet.contains(object) {
                print("found duplicated object %@", object.description)
            } else {
                allSet.insert(object)
            }
        }
    }
    
    private func indexPath(row: Int) -> IndexPath {
        #if os(iOS)
        IndexPath(row: row, section: 0)
        #else
        IndexPath(item: row, section: 0)
        #endif
    }
    
    func reload(oldData: [AnyHashable], newData: [AnyHashable], deferred: (()->())?, updateObjects: (()->())?, addAnimation: TableViewAnimation, deleteAnimation: TableViewAnimation) {
        
        var toAdd: [IndexPath] = []
        var toDelete: [IndexPath] = []
        
        let oldDataSet = Set(oldData)
        let newDataSet = Set(newData)
        
        if oldDataSet.count != oldData.count {
            printDuplicates(oldData)
        }
        if newDataSet.count != newData.count {
            printDuplicates(newData)
        }
        
        let currentSet = NSMutableOrderedSet(array: oldData)
        for (index, object) in oldData.enumerated() {
            if !newDataSet.contains(object) {
                toDelete.append(indexPath(row: index))
                currentSet.remove(object)
            }
        }
        for (index, object) in newData.enumerated() {
            if !oldDataSet.contains(object) {
                toAdd.append(indexPath(row: index))
                currentSet.insert(object, at: index)
            }
        }
        
        var itemsToMove: [(from: IndexPath, to: IndexPath)] = []
        for (index, object) in newData.enumerated() {
            let oldDataIndex = currentSet.index(of: object)
            if index != oldDataIndex {
                itemsToMove.append((from: indexPath(row: oldData.firstIndex(of: object)!), to: indexPath(row: index)))
            }
        }
        
        beginUpdates()
        
        updateObjects?()
        
        if !toDelete.isEmpty {
            #if os(iOS)
            deleteRows(at: toDelete, with: deleteAnimation)
            #else
            removeRows(at: IndexSet(toDelete.map { $0.item }), withAnimation: deleteAnimation)
            #endif
        }
        if !toAdd.isEmpty {
            #if os(iOS)
            insertRows(at: toAdd, with: addAnimation)
            #else
            insertRows(at: IndexSet(toAdd.map { $0.item }), withAnimation: addAnimation)
            #endif
        }
        if !itemsToMove.isEmpty {
            for couple in itemsToMove {
                #if os(iOS)
                moveRow(at: couple.from, to: couple.to)
                #else
                moveRow(at: couple.from.item, to: couple.to.item)
                #endif
            }
        }
        deferred?()
        
        endUpdates()
    }
}
