//
//  BoundsResizableLayout.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

open class BoundsResizableLayout: PlatformCollectionFlowLayout {
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: PlatformRect) -> Bool {
        if scrollDirection == .horizontal {
            return newBounds.height != collectionViewContentSize.height
        } else {
            return newBounds.width != collectionViewContentSize.width
        }
    }
    
    open override func invalidationContext(forBoundsChange newBounds: CGRect) -> PlatformInvalidationContext {
        #if os(iOS)
        let context = UICollectionViewFlowLayoutInvalidationContext()
        #else
        let context = NSCollectionViewFlowLayoutInvalidationContext()
        #endif
        context.invalidateFlowLayoutAttributes = true
        context.invalidateFlowLayoutDelegateMetrics = true
        return context
    }
}
