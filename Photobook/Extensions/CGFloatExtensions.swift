//
//  CGFloatExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

// Utils for CGFloat
extension CGFloat {
    
    
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
}
