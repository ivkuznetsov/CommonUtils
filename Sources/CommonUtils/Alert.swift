//
//  Alert.swift
//

#if os(macOS)

import AppKit

extension NSAlert: NSTextFieldDelegate {
    
    private static var textFieldBlock = "textFieldBlock"
    
    public static func showTextField(_ message: String,
                                     details: String? = nil,
                                     alertStyle: NSAlert.Style = .informational,
                                     cancelTitle: String = "Cancel",
                                     textDidUpdate: ((NSAlert, NSTextField)->())? = nil,
                                     buttons: [(title: String, action: ((NSTextField)->())?)],
                                     window: NSWindow? = nil) {
        
        let textField = NSTextField(frame: NSRect(origin: .zero, size: CGSize(width: 200, height: 24)))
        
        show(message,
             details: details,
             alertStyle: alertStyle,
             canCancel: true,
             customize: { alert in
            
            textField.delegate = alert
            alert.accessoryView = textField
            if let textDidUpdate = textDidUpdate {
                objc_setAssociatedObject(alert, &textFieldBlock, textDidUpdate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                textDidUpdate(alert, textField)
            }
            
        }, buttons: buttons.map { title, action in
            (title, { action?(textField) }) }, window: window)
    }
    
    public func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField,
            accessoryView == textField,
           let didUpdate = objc_getAssociatedObject(self, &NSAlert.textFieldBlock) as? (NSAlert, NSTextField)->() {
            
            didUpdate(self, textField)
        }
    }
    
    public static func show(_ error: Error, title: String) {
        show(title, details: error.localizedDescription, alertStyle: .critical)
    }
    
    public static func show(_ message: String,
                            details: String? = nil,
                            alertStyle: NSAlert.Style = .informational,
                            canCancel: Bool = false,
                            customize: ((NSAlert)->())? = nil,
                            buttons: [(title: String, action: (()->())?)] = [("OK", nil)],
                            window: NSWindow? = nil) {
        
        let alert = NSAlert()
        alert.alertStyle = alertStyle
        alert.messageText = message
        alert.informativeText = details ?? ""
        
        var actions = buttons
        if canCancel {
            actions.append(("Cancel", nil))
        }
        
        actions.forEach { title, action in
            alert.addButton(withTitle: title)
        }
        
        customize?(alert)
        
        if let window = window, window.isVisible {
            alert.beginSheetModal(for: window) { response in
                let index = response.rawValue - 1000
                actions[index].action?()
            }
        } else {
            let index = alert.runModal().rawValue - 1000
            actions[index].action?()
        }
    }
}

#else

import UIKit

public class Alert {
    
    fileprivate static let shared = Alert()
    
    public static let defaultTitle: String = {
        Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary!["CFBundleName"] as! String
    }()
    
    @discardableResult
    public static func present(title: String? = defaultTitle,
                               message: String?,
                               cancel: String? = nil,
                               other: [(String, (()->())?)] = [],
                               on vc: UIViewController) -> UIAlertController {
        present(title: title, message: message, cancel: (cancel ?? "OK", nil), other: other, on: vc)
    }
    
    @discardableResult
    public static func present(title: String? = defaultTitle,
                               message: String?,
                               cancel: (String, (()->())?),
                               other: [(String, (()->())?)],
                               on vc: UIViewController) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancel.0, style: .cancel) { (_) in
            cancel.1?()
        })
        
        for action in other {
            alert.addAction(UIAlertAction(title: action.0, style: .default, handler: { (_) in
                action.1?()
            }))
        }
        vc.present(alert, animated: true, completion: nil)
        return alert
    }
    
    private static var associatedActions: [UITextField : UIAlertAction] = [:]
    
    @discardableResult
    public static func present(title: String? = defaultTitle,
                               message: String?,
                               cancel: (String, (()->())?),
                               other: [(String, (([UITextField])->())?)],
                               fieldsSetup: [(UITextField)->()],
                               on viewController: UIViewController) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        var firstAction: UIAlertAction?
        var fields: [UITextField] = []
        for setubBlock in fieldsSetup {
            alert.addTextField(configurationHandler: { textfield in
                textfield.clearButtonMode = .whileEditing
                setubBlock(textfield)
                textfield.addTarget(shared, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                fields.append(textfield)
                
                DispatchQueue.main.async {
                    shared.textFieldDidChange(textfield)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: cancel.0, style: .cancel) { (_) in
            cancel.1?()
            clear(fields: fields)
        })
        for action in other {
            alert.addAction(UIAlertAction(title: action.0, style: .default, handler: { (_) in
                action.1?(fields)
                clear(fields: fields)
            }))
        }
        firstAction = alert.actions.first(where: { $0.style != .cancel })
        
        viewController.present(alert, animated: true, completion: nil)
        
        if let action = firstAction {
            for field in fields {
                associatedActions[field] = action
            }
        }
        return alert
    }
    
    private static func clear(fields: [UITextField]) {
        fields.forEach { associatedActions[$0] = nil }
    }
    
    @objc private func textFieldDidChange(_ field: UITextField) {
        type(of: self).associatedActions[field]?.isEnabled = field.text?.isEmpty == false
    }
    
    public enum Presentation {
        case barItem(UIBarButtonItem, vc: UIViewController)
        case view(UIView, rect: CGRect)
    }
    
    @discardableResult
    public static func presentSheet(title: String? = defaultTitle,
                                    message: String?,
                                    cancel: (String, (()->())?),
                                    other: [(String, (()->())?)],
                                    destructive: Int? = nil,
                                    on presentation: Presentation,
                                    tintColor: UIColor? = nil,
                                    overrideLightStyle: Bool = false) -> UIAlertController {
        
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: cancel.0, style: .cancel) { (_) in
            cancel.1?()
        })
        for (index, action) in other.enumerated() {
            sheet.addAction(UIAlertAction(title: action.0, style: index == destructive ? .destructive : .default, handler: { (_) in
                action.1?()
            }))
        }
        
        if overrideLightStyle {
            if #available(iOSApplicationExtension 13.0, *) {
                sheet.overrideUserInterfaceStyle = .light
            }
        }
        
        if let color = tintColor {
            sheet.view.tintColor = color
        }
        
        switch presentation {
        case let .barItem(barItem, vc: vc):
            sheet.popoverPresentationController?.barButtonItem = barItem
            vc.present(sheet, animated: true, completion: nil)
        case let .view(view, rect: rect):
            sheet.popoverPresentationController?.sourceRect = rect
            sheet.popoverPresentationController?.sourceView = view
            
            var responder: UIResponder? = view.next
            while responder != nil && responder as? UIViewController == nil {
                responder = responder!.next
            }
            (responder as! UIViewController).present(sheet, animated: true, completion: nil)
        }
        return sheet
    }
}

#endif
