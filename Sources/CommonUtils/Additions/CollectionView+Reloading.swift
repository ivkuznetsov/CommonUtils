//
//  CollectionView+Reloading.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension PlatformCollectionView {
    
    func reload(animated: Bool,
                expandBottom: Bool,
                oldData: [AnyHashable],
                newData: [AnyHashable],
                updateObjects: ()->(),
                completion: @escaping ()->()) {
        
        let diff = newData.diff(oldData: oldData)
        
        func update() -> () {
            updateObjects()
            deleteItems(at: diff.delete)
            insertItems(at: diff.add)
            diff.move.forEach { moveItem(at: $0, to: $1) }
            
            #if os(iOS)
            indexPathsForVisibleItems().forEach {
                let cell = cellForItem(at: $0)
                if diff.add.contains($0) {
                    cell?.superview?.sendSubviewToBack(cell)
                } else {
                    cell?.superview?.bringSubviewToFront(cell)
                }
            }
            #endif
        }
        
        #if os(iOS)
        let application = self.application
        application?.value(forKey: "beginIgnoringInteractionEvents")
        
        let performChanges = {
            self.performBatchUpdates { update() } completion: { _ in
                application?.value(forKey: "endIgnoringInteractionEvents")
                completion?()
            }
        }
        
        if animated {
            performChanges()
        } else {
            UIView.performWithoutAnimation(performChanges)
        }

        if collectionViewLayout.collectionViewContentSize.height < bounds.size.height && newData.count > 0 {
            UIView.animate(withDuration: animated ? 0.3 : 0) { [weak self] in
                self?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
            }
        }
        
        #else
        
        let oldRect = enclosingScrollView?.documentVisibleRect ?? .zero
        let oldSize = collectionViewLayout?.collectionViewContentSize ?? .zero
        
        if animated && window != nil && oldData.count > 0 && newData.count > 0 && applicationActive {
            NSAnimationContext.runAnimationGroup({ context in
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction.customEaseOut
                
                animator().performBatchUpdates {
                    update()
                } completionHandler: { [weak self] _ in
                    self?.layoutSubtreeIfNeeded()
                    completion()
                }
                updateScroll(oldRect: oldRect, oldSize: oldSize, expandBottom: expandBottom)
            }, completionHandler: nil)
        } else {
            performBatchUpdates { update() } completionHandler: { [weak self] _ in
                self?.layoutSubtreeIfNeeded()
                self?.updateScroll(oldRect: oldRect, oldSize: oldSize, expandBottom: expandBottom)
                completion()
            }
        }
        #endif
    }
    
#if os(iOS)
    private var application: UIApplication? {
        if Bundle.main.bundleURL.pathExtension != "appex" {
            return (UIApplication.value(forKey: "sharedApplication") as! UIApplication)
        }
        return nil
    }
#else
    private func updateScroll(oldRect: NSRect, oldSize: NSSize, expandBottom: Bool) {
        if let scrollView = enclosingScrollView, let layout = collectionViewLayout {
            let offset = scrollView.documentVisibleRect
            
            if offset.maxY > layout.collectionViewContentSize.height || (offset.origin.y < 0 && layout.collectionViewContentSize.height <= offset.size.height) {
                let point = NSPoint(x: 0, y: max(0, layout.collectionViewContentSize.height - offset.height))
                
                scrollView.documentView?.scroll(point)
            } else if !expandBottom {
                let point = NSPoint(x: 0, y: max(0, layout.collectionViewContentSize.height - (oldSize.height - oldRect.origin.y)))
                scrollView.documentView?.scroll(point)
            }
        }
    }
#endif
    
    private var applicationActive: Bool {
        #if os(iOS)
        application?.applicationState == .active
        #else
        true
        #endif
    }
}
