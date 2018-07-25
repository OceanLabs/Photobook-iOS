//
//  UITextFieldExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 19/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension UITextField {
    
    func scaleFont() {
        if #available(iOS 11.0, *), let font = self.font {
            self.font = UIFontMetrics.default.scaledFont(for: font)
            self.adjustsFontForContentSizeCategory = true
        }
    }
}
