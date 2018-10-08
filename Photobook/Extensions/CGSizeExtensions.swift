//
//  CGSizeExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 13/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension CGSize {
    
    func resizeAspectFill(_ targetSize: CGSize) -> CGSize {
        let sourceAspectRatio = self.width / self.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        if sourceAspectRatio >= targetAspectRatio {
            return CGSize(width: targetSize.height * sourceAspectRatio, height: targetSize.height)
        }
        else{
            return CGSize(width: targetSize.width, height: targetSize.width / sourceAspectRatio)
        }
    }

    static func * (size: CGSize, scalar: CGFloat) -> CGSize {
        return CGSize(width: size.width * scalar, height: size.height * scalar)
    }    
    static func * (scalar: CGFloat, size: CGSize) -> CGSize { return size * scalar }

    static func * (size: CGSize, scalar: Double) -> CGSize { return size * CGFloat(scalar) }
    static func * (scalar: Double, size: CGSize) -> CGSize { return size * scalar }

    static func ==~(lhs: CGSize, rhs: CGSize) -> Bool {
        return (abs(lhs.width - rhs.width) <= CGFloat.minPrecision) &&
                (abs(lhs.height - rhs.height) <= CGFloat.minPrecision)
    }
}
