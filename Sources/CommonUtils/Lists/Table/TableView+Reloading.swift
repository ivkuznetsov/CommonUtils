//
//  UITableView+Reloading.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension PlatformTableView {
    
    func setNeedUpdateHeights() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateHeights), object: nil)
        perform(#selector(updateHeights), with: nil, afterDelay: 0)
    }
    
    @objc private func updateHeights() {
        beginUpdates()
        endUpdates()
    }
    
    var defaultWidth: CGFloat {
        #if os(iOS)
        frame.width - contentInset.left - contentInset.right - safeAreaInsets.left - safeAreaInsets.right
        #else
        if let scrollView = enclosingScrollView {
            let contentInsets = scrollView.contentInsets
            return scrollView.width - contentInsets.left - contentInsets.right - (scrollView.verticalScroller?.width ?? 0)
        }
        return width
        #endif
    }
    
    #if os(iOS)
    static var cellsKey = "cellsKey"
    private var registeredCells: Set<String> {
        get { objc_getAssociatedObject(self, &PlatformCollectionView.cellsKey) as? Set<String> ?? Set() }
        set { objc_setAssociatedObject(self, &PlatformCollectionView.cellsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    #endif
    
    func createCell<T: PlatformTableCell>(for type: T.Type, identifier: String? = nil, source: CellSource = .nib) -> T {
        let className = type.classNameWithoutModule()
        let id = identifier ?? className
        
    #if os(iOS)
        if !registeredCells.contains(id) {
            switch source {
            case .nib:
                register(UINib(nibName: className, bundle: Bundle(for: type)), forCellReuseIdentifier: id)
            case .code:
                register(type, forCellReuseIdentifier: id)
            }
            registeredCells.insert(id)
        }
        return dequeueReusableCell(withIdentifier: id) as! T
        #else
        
        let itemId = NSUserInterfaceItemIdentifier(rawValue: id)
        let cell = (makeView(withIdentifier: itemId, owner: nil) ?? type.loadFromNib()) as! T
        cell.identifier = itemId
        return cell
        #endif
    }
    
    func reload(oldData: [AnyHashable],
                newData: [AnyHashable],
                updateObjects: (_ deleted: Set<Int>)->(),
                addAnimation: PlatformTableViewAnimation,
                deleteAnimation: PlatformTableViewAnimation,
                animated: Bool) {
        
        let diff = newData.diff(oldData: oldData)
        
        func update() {
            beginUpdates()
            updateObjects(Set(diff.delete.map { $0.item }))
            
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
