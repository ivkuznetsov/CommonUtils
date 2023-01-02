//
//  BaseTableViewCell.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

open class BaseTableViewCell: PlatformTableCell {
    
    #if os(iOS)
    open override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(white: 0.5, alpha: 0.1)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.separatorHidden = separatorHidden
    }
    
    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        reloadSelection(animated: animated)
    }
    
    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        reloadSelection(animated: animated)
    }
    
    open func reloadSelection(animated: Bool) { }
    #else
    
    open override func drawSeparator(in dirtyRect: NSRect) {
        if !isSelected && !isNextRowSelected {
            super.drawSeparator(in: dirtyRect)
        }
    }

    open override var isNextRowSelected: Bool {
        get { super.isNextRowSelected }
        set {
            super.isNextRowSelected = newValue
            self.needsDisplay = true
        }
    }
    #endif
}

#if os(iOS)
public extension UITableViewCell {
    
    var separatorHidden: Bool {
        set { separatorViews.forEach { $0.isHidden = newValue } }
        get { separatorViews.first?.isHidden ?? true }
    }
    
    private var separatorViews: [UIView] {
        subviews.filter { String(describing: type(of: $0)).contains("SeparatorView") }
    }
}
#endif
