//
//  CGFloatExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

infix operator ==~: ComparisonPrecedence

// Utils for CGFloat
extension CGFloat {

    static let minPrecision: CGFloat = 0.01
    
    /// Whether the instance is in between 0.0 and 1.0 (inclusive)
    var isNormalised: Bool {
        return self >= 0.0 && self <= 1.0
    }
    
    /// Converts the value of the instance from radians to degrees
    ///
    /// - Returns: The value in degrees
    func inDegrees() -> CGFloat {
        return self * 180.0 / .pi
    }
    
    static func ==~(lhs: CGFloat, rhs: CGFloat) -> Bool {
        let difference = abs(lhs - rhs)
        
        if lhs == rhs {
            return true
        } else if lhs == 0.0 || rhs == 0.0 || difference < CGFloat.leastNormalMagnitude {
            return difference < (minPrecision * CGFloat.leastNormalMagnitude)
        } else {
            let absA = abs(lhs)
            let absB = abs(rhs)

            return difference / (absA + absB) < minPrecision
        }
    }
}
