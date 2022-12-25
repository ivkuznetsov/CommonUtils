//
//  FooterLoadingView.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

open class FooterLoadingView: PlatformView {

    public enum State {
        case stop
        case loading
        case failed
    }
    
    #if os(iOS)
    @IBOutlet open var indicatorView: UIActivityIndicatorView!
    #else
    @IBOutlet public var indicatorView: NSProgressIndicator!
    #endif
    @IBOutlet open var retryButton: PlatformButton!
    
    open var state: State = .stop {
        didSet {
            if state != oldValue {
                retryButton.isHidden = state != .failed
                #if os(iOS)
                if state == .loading {
                    indicatorView.startAnimating()
                } else {
                    indicatorView.stopAnimating()
                }
                #else
                if state == .loading {
                    indicatorView.startAnimation(nil)
                } else {
                    indicatorView.stopAnimation(nil)
                }
                #endif
            }
        }
    }
    var retry: (()->())?
    
    @IBAction private func retryAction(_ sender: Any?) {
        retry?()
    }
}
