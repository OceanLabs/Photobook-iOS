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
    
    var isNormalised: Bool {
        return self >= 0.0 && self <= 1.0
    }
}
