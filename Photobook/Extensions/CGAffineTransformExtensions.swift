//
//  CGAffineTransformExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension CGAffineTransform {
    
    /// Rotation angle
    var angle: CGFloat {
        return atan2(self.b, self.a)
    }
    
    /// Scale. Assumes that the scale on the X and Y axes is the same.
    var scale: CGFloat {
        return sqrt(self.a * self.a + self.c * self.c)
    }
    
    static func ==~(lhs: CGAffineTransform, rhs: CGAffineTransform) -> Bool {
        return (abs(lhs.a - rhs.a) <= CGFloat.minPrecision) &&
            (abs(lhs.b - rhs.b) <= CGFloat.minPrecision) &&
            (abs(lhs.c - rhs.c) <= CGFloat.minPrecision) &&
            (abs(lhs.d - rhs.d) <= CGFloat.minPrecision) &&
            (abs(lhs.tx - rhs.tx) <= CGFloat.minPrecision) &&
            (abs(lhs.ty - rhs.ty) <= CGFloat.minPrecision)
    }
}

