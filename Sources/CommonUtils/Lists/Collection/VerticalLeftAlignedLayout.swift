//
//  VerticalLeftAlignedLayout.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public class VerticalLeftAlignedLayout: BoundsResizableLayout {

    public override init() {
        super.init()
        scrollDirection = .vertical
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = .vertical
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
    }
    
    override public func layoutAttributesForElements(in rect: PlatformRect) -> [PlatformLayoutAttribute] {
        let attrs: [PlatformLayoutAttribute]? = super.layoutAttributesForElements(in: rect)
        let inherited = (attrs ?? []).map { $0.copy() as! PlatformLayoutAttribute }
        
        #if os(iOS)
        let category = UICollectionView.ElementCategory.cell
        #else
        let category = NSCollectionElementCategory.item
        #endif
        
        for attributes in inherited where attributes.representedElementCategory == category {
            let indexPath: IndexPath? = attributes.indexPath
            if let indexPath = indexPath, let adjustedFrame = layoutAttributesForItem(at: indexPath)?.frame {
                attributes.frame = adjustedFrame
            }
        }
        return inherited
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> PlatformLayoutAttribute? {
        guard let current = super.layoutAttributesForItem(at: indexPath)?.copy()
            as? PlatformLayoutAttribute else { return nil }
        
        var describesFirstItemInLine: Bool {
            guard indexPath.item > 0 else { return true }
            guard let preceding = super.layoutAttributesForItem(at: indexPath.preceding) else { return true }
            return !isFrame(for: current, inSameLineAsFrameFor: preceding)
        }

        if describesFirstItemInLine {
            current.frame.origin.x = inset(forSection: indexPath.section).left
        } else {
            let offset = minimumInteritemSpacing(forSection: indexPath.section)
            if let preceding = layoutAttributesForItem(at: indexPath.preceding) {
                current.frame.origin.x = preceding.frame.maxX + offset
            }
        }

        return current
    }

    private func isFrame(for firstItemAttributes: PlatformLayoutAttribute, inSameLineAsFrameFor secondItemAttributes: PlatformLayoutAttribute) -> Bool {
        let indexPath: IndexPath? = firstItemAttributes.indexPath
        
        guard let section = indexPath?.section else { return false }

        if firstItemAttributes.size.height == 0 || secondItemAttributes.frame.size.height == 0 { return false }
        
        let sectionInset = inset(forSection: section)
        var availableContentWidth: CGFloat? {
            guard let collectionViewWidth = collectionView?.frame.size.width else { return nil }
            return collectionViewWidth - sectionInset.left - sectionInset.right
        }
        guard let lineWidth = availableContentWidth else { return false }

        let lineFrame = CGRect(x: sectionInset.left, y: firstItemAttributes.frame.origin.y,
                               width: lineWidth, height: firstItemAttributes.frame.size.height)
        
        return lineFrame.intersects(secondItemAttributes.frame)
    }

    private func minimumInteritemSpacing(forSection section: Int) -> CGFloat {
        guard let collectionView = self.collectionView else { return minimumInteritemSpacing}

        let delegate = collectionView.delegate as? PlatformLayoutDelegate
        return delegate?.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) ?? minimumInteritemSpacing
    }

    private func inset(forSection section: Int) -> PlatformInset {
        guard let collectionView = self.collectionView else { return sectionInset }

        let delegate = collectionView.delegate as? PlatformLayoutDelegate
        return delegate?.collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? sectionInset
    }
}

fileprivate extension IndexPath {
    
    var preceding: IndexPath {
        precondition(item > 0)
        return IndexPath(item: item - 1, section: section)
    }
}
