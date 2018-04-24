//
//  CGRectExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

extension CGRect {
    
    static func ==~(lhs: CGRect, rhs: CGRect) -> Bool {
        return (fabs(lhs.minX - rhs.minX) <= CGFloat.minPrecision) &&
            (fabs(lhs.minY - rhs.minY) <= CGFloat.minPrecision) &&
            (fabs(lhs.width - rhs.width) <= CGFloat.minPrecision) &&
            (fabs(lhs.height - rhs.height) <= CGFloat.minPrecision)
    }
}
