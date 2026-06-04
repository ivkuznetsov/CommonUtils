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
        
        guard let cgImage,
              side > minSide, size.width > 0 && size.height > 0 else { return self }
        
        let size = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let newSize: CGSize
        
        if size.width < size.height {
            newSize = CGSize(width: minSide, height: minSide * size.height / size.width)
        } else {
            newSize = CGSize(width: minSide * size.width / size.height, height: minSide)
        }
        
        let options = UIGraphicsImageRendererFormat()
        options.scale = 1
        options.opaque = false
        
        let result = UIGraphicsImageRenderer(size: CGSize(width: minSide, height: minSide), format: options).image { ctx in
            ctx.cgContext.translateBy(x: 0, y: newSize.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.draw(cgImage, in: CGRect(x: minSide / 2 - newSize.width / 2,
                                                   y: newSize.height / 2 - minSide / 2,
                                                   width: newSize.width, height: newSize.height),
                               byTiling: false)
        }.cgImage!
        
        return UIImage(cgImage: result, scale: 1, orientation: imageOrientation)
    }
    
    func resize(_ size: CGSize) -> UIImage {
        guard let cgImage else { return self }
        
        let options = UIGraphicsImageRendererFormat()
        options.scale = 1
        options.opaque = false
        
        let result = UIGraphicsImageRenderer(size: size, format: options).image { ctx in
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.draw(cgImage, in: .init(origin: .zero, size: size), byTiling: false)
        }.cgImage!
        
        return UIImage(cgImage: result, scale: 1, orientation: imageOrientation)
    }
    
    func reduced(_ maxSide: CGFloat) -> UIImage {
        guard let cgImage,
              (size.width > maxSide || size.height > maxSide) && size.width > 0 && size.height > 0 else { return self }
        
        let size = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let resultSize: CGSize
        
        if size.width > size.height {
            resultSize = .init(width: maxSide, height: floor(maxSide * size.height / size.width))
        } else {
            resultSize = .init(width: floor(maxSide * size.width / size.height), height: maxSide)
        }
        return resize(resultSize)
    }
}

#endif
