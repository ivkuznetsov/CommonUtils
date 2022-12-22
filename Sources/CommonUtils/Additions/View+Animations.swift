//
//  View+Animations.swift
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

public extension PlatformView {
    
    #if os(iOS)
    
    var imageRepresentation: UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    private var viewLayer: CALayer { return layer }
    
    #else
    
    private var viewLayer: CALayer { return layer! }
    
    #endif
    
    func addFadeTransition() {
        addFadeTransition(duration: 0.15)
    }
    
    func addShake() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.duration = 0.07
        animation.autoreverses = true
        animation.repeatCount = 3
        animation.isRemovedOnCompletion = true
        animation.fromValue = NSNumber(floatLiteral: -0.05)
        animation.toValue = NSNumber(floatLiteral: 0.05)
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        viewLayer.add(animation, forKey: "shake")
    }
    
    func addFadeTransition(duration: Double) {
        if viewLayer.animation(forKey: "fade") != nil {
            return
        }
        let transition = CATransition()
        transition.type = .fade
        transition.duration = duration
        transition.fillMode = .both
        viewLayer.add(transition, forKey: "fade")
    }
    
    func addPushTransition() {
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
    
    func addPopTransition() {
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromLeft
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
    
    func addMoveInTransition() {
        let transition = CATransition()
        transition.type = .moveIn
        transition.subtype = .fromRight
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
    
    func addMoveOutTransition() {
        let transition = CATransition()
        transition.type = .moveIn
        transition.subtype = .fromLeft
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
    
    func addPresentTransition() {
        let transition = CATransition()
        transition.type = .moveIn
        transition.subtype = .fromTop
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
    
    func addDismissTransition() {
        let transition = CATransition()
        transition.type = .moveIn
        transition.subtype = .fromBottom
        transition.duration = 0.4
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
    
    func addDismissFromTop() {
        let transition = CATransition()
        transition.type = .moveIn
        transition.subtype = .fromTop
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1)
        viewLayer.add(transition, forKey: "transition")
    }
}

public extension CAMediaTimingFunction {
    
    static var customEaseOut: CAMediaTimingFunction { CAMediaTimingFunction(controlPoints: 0.4, 0, 0, 1) }
}

public extension CALayer {
    
    func transitionTo(y: CGFloat, completion: @escaping ()->()) {
        var position = self.position
        position.y = y
        transitionTo(position: position, completion: completion)
    }
    
    func transitionTo(position: CGPoint, completion: @escaping ()->()) {
        CATransaction.begin()
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.3
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.toValue = position
        
        animation.timingFunction = CAMediaTimingFunction.customEaseOut
        
        CATransaction.setCompletionBlock{ [weak self] in
            self?.removeAnimation(forKey: "translate")
            completion()
        }
            
        add(animation, forKey: "translate")
        CATransaction.commit()
    }
}
