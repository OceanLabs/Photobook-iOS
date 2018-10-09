//
//  CGRectExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension CGRect {
    
    static func ==~(lhs: CGRect, rhs: CGRect) -> Bool {
        return (abs(lhs.minX - rhs.minX) <= CGFloat.minPrecision) &&
            (abs(lhs.minY - rhs.minY) <= CGFloat.minPrecision) &&
            (abs(lhs.width - rhs.width) <= CGFloat.minPrecision) &&
            (abs(lhs.height - rhs.height) <= CGFloat.minPrecision)
    }
}
