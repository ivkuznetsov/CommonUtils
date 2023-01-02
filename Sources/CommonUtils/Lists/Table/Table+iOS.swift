//
//  Table+iOS.swift
//  
//
//  Created by Ilya Kuznetsov on 31/12/2022.
//

#if os(iOS)
import UIKit

extension Table: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell: UITableViewCell
        
        if let item = item as? UITableViewCell {
            cell = item
        } else if let item = item as? UIView {
            let tableCell = view.createCell(for: ContainerTableCell.self, identifier: "\(item.hash)", source: .code)
            tableCell.attach(viewToAttach: item, type: .constraints)
            setupViewContainer?(tableCell)
            cell = tableCell
        } else {
            guard let createCell = self.cell(item) else {
                fatalError("Please specify cell for \(item)")
            }
            cell = view.createCell(for: createCell.info.type,
                                   identifier: createCell.info.identifier,
                                   source: createCell.info.source)
            createCell.info.fill(item, cell)
        }
        cell.width = tableView.width
        cell.layoutIfNeeded()
        cell.separatorHidden = (indexPath.row == items.count - 1) && view.tableFooterView != nil
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.row]
        
        var height = cachedSize(for: item)
        
        if height == nil {
            height = cell(item)?.info.size(item)
            if height != UITableView.automaticDimension {
                cache(size: height, for: item)
            }
        }
        return height ?? UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if !useAutomaticHeights {
            return self.tableView(tableView, heightForRowAt: indexPath)
        }
        
        let item = items[indexPath.row]
        if let cell = item as? UITableViewCell {
            return cell.bounds.height
        } else if let cell = item as? UIView {
            return cell.systemLayoutSizeFitting(CGSize(width: tableView.width,
                                                       height: CGFloat.greatestFiniteMagnitude)).height
        } else if let value = cachedSize(for: item) {
            return value
        } else if let value = cell(item)?.estimatedHeight(item) {
            return value
        }
        return 150
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = items[indexPath.row]
        
        if let editor = cell(item)?.editor?(item) {
            return editor.style != .none
        }
        return false
    }
}

extension Table: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        if cell(item)?.info.action(item) == .deselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if useAutomaticHeights, let indexPath = tableView.indexPath(for: cell) {
            cache(size: cell.bounds.height, for: items[indexPath.row])
        }
        delegate.without(self) {
            (delegate as? UITableViewDelegate)?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        if let editor = cell(item)?.editor?(item) {
            switch editor {
            case .delete(let action): action()
            case .insert(let action): action()
            default: break
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        
        if let editor = cell(item)?.editor?(item),
           case .actions(let actions) = editor {
            let configuration = UISwipeActionsConfiguration(actions: actions())
            configuration.performsFirstActionWithFullSwipe = false
            return configuration
        }
        return nil
    }
    
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let item = items[indexPath.row]
        
        if let editor = cell(item)?.editor?(item) {
            return editor.style
        }
        return .none
    }
}

extension Table: UITableViewDataSourcePrefetching {
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            let item = items[$0.row]
            if let cancel = cell(item)?.prefetch?(item) {
                prefetchTokens[$0] = cancel
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            prefetchTokens[$0]?.cancel()
            prefetchTokens[$0] = nil
        }
    }
}
#endif
