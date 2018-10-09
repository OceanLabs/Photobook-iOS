//
//  UIColorExtensions.swift
//  Photobook
//
//  Created by Julian Gruber on 06/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension UIColor {
    
    var hex: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "#%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }
    
}
