//
//  DoubleExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 11/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension Double {
    
    /// Whether the instance is in between 0.0 and 1.0 (inclusive)
    var isNormalised: Bool {
        return self >= 0.0 && self <= 1.0
    }
}
