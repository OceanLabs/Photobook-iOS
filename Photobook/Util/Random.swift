//
//  Random.swift
//  Photobook
//
//  Created by Julian Gruber on 08/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class Random {
    /** Returns a random floating point number between 0.0 and 1.0, inclusive. */
    public static var double: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
    
    /**
     Random double between min and max
     
     - parameter min: minimum possible generated random value
     - parameter max: maximum possible generated random value
     
     - returns: a random double point number between 0 and n max
     */
    public static func double(min: Double, max: Double) -> Double {
        return Random.double * (max - min) + min
    }
}
