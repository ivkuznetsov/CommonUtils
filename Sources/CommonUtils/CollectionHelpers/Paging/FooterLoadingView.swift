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
    let indicatorView: UIActivityIndicatorView
    #else
    let indicatorView: NSProgressIndicator
    #endif
    let retryButton: PlatformButton!
    
    public init() {
        #if os(iOS)
        indicatorView = UIActivityIndicatorView(style: .medium)
        retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        #else
        indicatorView = NSProgressIndicator()
        indicatorView.style = .spinning
        retryButton = NSButton()
        retryButton.bezelStyle = .texturedRounded
        retryButton.title = "Retry"
        #endif
        super.init(frame: .zero)
        
        #if os(iOS)
        retryButton.addTarget(self, action: #selector(retryAction), for: .touchUpInside)
        #else
        retryButton.target = self
        retryButton.action = #selector(retryAction)
        #endif
        attach(retryButton, position: .center)
        attach(indicatorView, position: .center)
        
        let constraint = heightAnchor.constraint(equalToConstant: 50)
        constraint.priority = .init(900)
        constraint.isActive = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    @objc private func retryAction() {
        retry?()
    }
}
