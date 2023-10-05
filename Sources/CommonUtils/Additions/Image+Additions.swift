//
//  UIImage+Additions.swift
//  
//
//  Created by Ilya Kuznetsov on 03/12/2022.
//

#if os(iOS)

import UIKit

public extension UIImage {
    
    func squareCroped(minSide: CGFloat) -> UIImage {
        let side = min(size.width, size.height)
        
        if side > minSide, size.width > 0 && size.height > 0 {
            let newSize: CGSize
            
            if size.width < size.height {
                newSize = CGSize(width: minSide, height: minSide * size.height / size.width)
            } else {
                newSize = CGSize(width: minSide * size.width / size.height, height: minSide)
            }
            
            UIGraphicsBeginImageContext(CGSize(width: minSide, height: minSide))
            draw(in: CGRect(x: minSide / 2 - newSize.width / 2, y: minSide / 2 - newSize.height / 2, width: newSize.width, height: newSize.height))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image!
        } else {
            return self
        }
    }
    
    func resize(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func reduced(_ maxSide: CGFloat) -> UIImage {
        if (size.width <= maxSide && size.height <= maxSide) || size.width == 0 || size.height == 0 { return self }
        
        let resultSize: CGSize
        
        if size.width > size.height {
            resultSize = .init(width: maxSide, height: floor(maxSide * size.height / size.width))
        } else {
            resultSize = .init(width: floor(maxSide * size.width / size.height), height: maxSide)
        }
        UIGraphicsBeginImageContext(CGSize(width: resultSize.width, height: resultSize.height))
        draw(in: CGRect(x: 0, y: 0, width: resultSize.width, height: resultSize.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

#endif
