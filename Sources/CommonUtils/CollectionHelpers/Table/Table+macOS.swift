//
//  Table+macOS.swift
//

#if os(macOS)
import AppKit

extension Table: NSTableViewDataSource, NSTableViewDelegate {
    
    public func numberOfRows(in tableView: NSTableView) -> Int { items.count }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? { nil }
    
    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let item = items[row]
        
        if let view = item as? NSView {
            let cell = list.createCell(for: ContainerTableCell.self, identifier: "\(view.hash)", source: .code)
            cell.attach(viewToAttach: view, type: .constraints)
            setupViewContainer?(cell)
            return cell
        } else if let createCell = cell(item)?.info {
            let cell = list.createCell(for: createCell.type, source: .nib)
            createCell.fill(item, cell)
            return cell
        }
        return nil
    }
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = items[row]
        var height = cachedSize(for: item)
        
        if height == nil {
            height = cell(item)?.info.size(item)
            cache(size: height, for: item)
        }
        return height ?? -1
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        let selected = list.selectedRowIndexes
        
        if selected.isEmpty {
            deselectedAll?()
        } else {
            selected.forEach {
                let item = items[$0]
                if cell(item)?.info.action(item) == .deselect {
                    list.deselectRow($0)
                }
            }
        }
    }
}

extension Table: NSMenuDelegate {
    
    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if let item = items[safe: list.clickedRow] {
            cell(item)?.menuItems(item).forEach { menu.addItem($0) }
        }
    }
}
#endif
