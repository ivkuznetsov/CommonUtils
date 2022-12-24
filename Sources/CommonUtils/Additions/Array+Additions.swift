//
//  File.swift
//  
//
//  Created by Ilya Kuznetsov on 23/12/2022.
//

import Foundation

public extension Array {
    
    subscript (safe index: Index) -> Element? {
        if index > 0 && index < count {
            return self[index]
        }
        return nil
    }
    
    mutating func appendSafe(_ element: Element?) {
        if let element = element {
            append(element)
        }
    }
}

public extension Array where Element == AnyHashable {
    
    //generate diff for TableView and CollectionView
    func diff(oldData: [AnyHashable]) -> (add: Set<IndexPath>,
                                          delete: Set<IndexPath>,
                                          move: [(from: IndexPath, to: IndexPath)]) {
        var toAdd = Set<IndexPath>()
        var toDelete = Set<IndexPath>()
        var toMove: [(IndexPath, IndexPath)] = []
        
        difference(from: oldData).inferringMoves().forEach {
            switch $0 {
            case let .remove(offset: oldIndex, element: _, associatedWith: newIndex):
                if let newIndex = newIndex {
                    toMove.append((IndexPath(item: oldIndex, section: 0), IndexPath(item: newIndex, section: 0)))
                } else {
                    toDelete.insert(IndexPath(item: oldIndex, section: 0))
                }
            case let .insert(offset: index, element: _, associatedWith: oldIndex):
                if oldIndex == nil {
                    toAdd.insert(IndexPath(item: index, section: 0))
                }
            }
        }
        return (toAdd, toDelete, toMove)
    }
}
