//
//  Collection+macOS.swift
//  
//
//  Created by Ilya Kuznetsov on 31/12/2022.
//

#if os(macOS)
import AppKit

extension Collection: NSCollectionViewDataSource {
    
    public func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { items.count }
    
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.item >= items.count { return NSCollectionViewItem() }
        
        let item = items[indexPath.item]
        
        if let view = item as? NSView {
            let item = list.createCell(for: ContainerCollectionItem.self, source: .code, at: indexPath)
            item.attach(view)
            setupViewContainer?(item)
            return item
        }
        
        let createItem = cell(item)!.info
        
        let cell = list.createCell(for: createItem.type, at: indexPath)
        _ = cell.view
        createItem.fill(item, cell)
        return cell
    }
}

extension Collection: NSCollectionViewDelegate {
    
    public func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        indexPaths.forEach {
            let item = items[$0.item]
            
            let result = cell(item)?.info.action(item)
            
            if result == nil || result! == .deselect {
                collectionView.deselectAll(nil)
            }
        }
    }
}

extension Collection: NSCollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if indexPath.item >= items.count { return .zero }
        
        let item = items[indexPath.item]
        
        if let view = item as? NSView {
            
            let defaultWidth = list.defaultWidth
            
            var resultSize: NSSize = .zero
            
            if view.superview != nil {
                view.superview?.width = defaultWidth
                resultSize = view.fittingSize
            } else {
                let widthConstraint = view.widthAnchor.constraint(equalToConstant: defaultWidth)
                widthConstraint.isActive = true
                view.layoutSubtreeIfNeeded()
                resultSize = view.fittingSize
                widthConstraint.isActive = false
            }
            resultSize.width = defaultWidth
            return NSSize(width: floor(resultSize.width), height: ceil(resultSize.height))
        } else {
            var size = cachedSize(for: item)
            if size == nil {
                size = cell(item)?.info.size(item)
                cache(size: size, for: item)
            }
            return size ?? .zero
        }
    }
}

#endif
