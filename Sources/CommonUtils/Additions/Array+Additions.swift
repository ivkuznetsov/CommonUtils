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
        var toMove: [(AnyHashable, IndexPath)] = []
        
        var currentData = oldData
        
        difference(from: oldData).inferringMoves().forEach {
            switch $0 {
            case let .insert(offset: index, element: element, associatedWith: oldIndex):
                if oldIndex == nil {
                    currentData.insert(element, at: index)
                    toAdd.insert(IndexPath(item: index, section: 0))
                } else {
                    toMove.append((element, IndexPath(item: index, section: 0)))
                }
            case let .remove(offset: index, element: _, associatedWith: oldIndex):
                if oldIndex == nil {
                    currentData.remove(at: index)
                    toDelete.insert(IndexPath(item: index, section: 0))
                }
            }
        }
        
        return (toAdd,
                toDelete,
                toMove.map { (IndexPath(item: currentData.firstIndex(of: $0.0)!, section: 0), to: $0.1) })
    }
}
