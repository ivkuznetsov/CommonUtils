//
//  CollectionView.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension PlatformCollectionView {
    
    func reload(animated: Bool,
                expandBottom: Bool,
                oldData: [AnyHashable],
                newData: [AnyHashable],
                updateObjects: ()->(),
                completion: @escaping ()->()) {
        
        let diff = newData.diff(oldData: oldData)
        
        func update() -> () {
            updateObjects()
            #if os(iOS)
            deleteItems(at: Array(diff.delete))
            insertItems(at: Array(diff.add))
            #else
            deleteItems(at: diff.delete)
            insertItems(at: diff.add)
            #endif
            diff.move.forEach { moveItem(at: $0, to: $1) }
            
            #if os(iOS)
            indexPathsForVisibleItems.forEach {
                if let cell = cellForItem(at: $0) {
                    if diff.add.contains($0) {
                        cell.superview?.sendSubviewToBack(cell)
                    } else {
                        cell.superview?.bringSubviewToFront(cell)
                    }
                }
            }
            #endif
        }
        
        #if os(iOS)
        let application = self.application
        application?.value(forKey: "beginIgnoringInteractionEvents")
        
        func performChanges() {
            performBatchUpdates { update() } completion: { _ in
                application?.value(forKey: "endIgnoringInteractionEvents")
                completion()
            }
        }
        
        if animated {
            performChanges()
        } else {
            UIView.performWithoutAnimation { performChanges() }
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
    
    enum Source {
        case nib
        case code
    }
    
    static var cellsKey = "cellsKey"
    private var registeredCells: Set<String> {
        get { objc_getAssociatedObject(self, &PlatformCollectionView.cellsKey) as? Set<String> ?? Set() }
        set { objc_setAssociatedObject(self, &PlatformCollectionView.cellsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func createCell<T: PlatformCollectionCell>(for type: T.Type, identifier: String? = nil, source: Source = .nib, at indexPath: IndexPath) -> T {
        let className = type.classNameWithoutModule()
        let id = identifier ?? className
        
        if !registeredCells.contains(id) {
            switch source {
            case .nib:
                #if os(iOS)
                register(UINib(nibName: className, bundle: Bundle(for: type)), forCellWithReuseIdentifier: id)
                #else
                register(NSNib(nibNamed: id, bundle: Bundle(for: type)), forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: id))
                #endif
            case .code:
                #if os(iOS)
                register(type, forCellWithReuseIdentifier: id)
                #else
                register(type, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: id))
                #endif
            }
            registeredCells.insert(id)
        }
        #if os(iOS)
        return dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! T
        #else
        return makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id), for: indexPath) as! T
        #endif
    }
    
#if os(iOS)
    var flowLayout: UICollectionViewFlowLayout? { collectionViewLayout as? UICollectionViewFlowLayout }
    
    private var application: UIApplication? {
        if Bundle.main.bundleURL.pathExtension != "appex" {
            return (UIApplication.value(forKey: "sharedApplication") as! UIApplication)
        }
        return nil
    }
    
    var defaultWidth: CGFloat {
        var width = self.width
        if let layout = flowLayout {
            width -= layout.sectionInset.left + layout.sectionInset.right + safeAreaInsets.left + safeAreaInsets.right
        }
        return width
    }
#else
    var flowLayout: NSCollectionViewFlowLayout? { collectionViewLayout as? NSCollectionViewFlowLayout }
    
    var defaultWidth: CGFloat {
        guard let scrollView = enclosingScrollView else { return width }
        
        let contentInsets = scrollView.contentInsets
        let sectionInsets = flowLayout?.sectionInset ?? NSEdgeInsets()
        var verticalScrollerWidth: CGFloat {
            guard let scroller = scrollView.verticalScroller else { return 0.0 }
            guard scroller.scrollerStyle != .overlay else { return 0.0 }
            return NSScroller.scrollerWidth(for: scroller.controlSize, scrollerStyle: scroller.scrollerStyle)
        }
        return scrollView.width - sectionInsets.left - sectionInsets.right - contentInsets.left - contentInsets.right - verticalScrollerWidth
    }
    
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
    
    func set(cellsPadding: CGFloat) {
        flowLayout?.sectionInset = .init(top: cellsPadding, left: cellsPadding, bottom: cellsPadding, right: cellsPadding)
        flowLayout?.minimumInteritemSpacing = cellsPadding
        flowLayout?.minimumLineSpacing = cellsPadding
    }
    
    private var applicationActive: Bool {
        #if os(iOS)
        application?.applicationState == .active
        #else
        true
        #endif
    }
}
