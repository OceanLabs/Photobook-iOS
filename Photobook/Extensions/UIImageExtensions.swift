//
//  UIImageExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

extension UIImage {
    
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    convenience init?(namedInPhotobookBundle: String) {
        self.init(named: namedInPhotobookBundle, in: photobookBundle, compatibleWith: nil)
    }
    
    
    /// Shrink an image
    ///
    /// - Parameters:
    ///   - size: The image size in points
    ///   - aspectFit: True for aspectFit, false for aspectFill
    func shrinkToSize(_ size: CGSize, aspectFit: Bool = false) -> UIImage {
        let scaleFactor = aspectFit ? max(size.width, size.height) / max(self.size.height, self.size.width) : max(size.width, size.height) / min(self.size.height, self.size.width)
        
        // We don't care about scaling up
        guard scaleFactor < 1 else { return self }
        
        let screenScale = UIScreen.main.usableScreenScale()
        let size = CGSize(width: self.size.width * scaleFactor * screenScale, height: self.size.height * scaleFactor * screenScale)
        
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = resizedImage, let cgImage = resizedImage?.cgImage else { return self }
        
        return UIImage(cgImage: cgImage, scale: screenScale, orientation: image.imageOrientation)
    }
    
}

