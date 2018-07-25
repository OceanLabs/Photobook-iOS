//
//  UILabelExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

extension UILabel {
    
    func setLineHeight(_ lineHeight: CGFloat) {
        guard let title = self.text else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.alignment = self.textAlignment
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let attrString = NSMutableAttributedString(string: title)
        attrString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        self.attributedText = attrString
    }
    
    func scaleFont() {
        if #available(iOS 11.0, *) {
            self.font = UIFontMetrics.default.scaledFont(for: self.font)
            self.adjustsFontForContentSizeCategory = true
        }
    }
}
