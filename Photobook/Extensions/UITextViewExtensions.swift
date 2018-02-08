//
//  UITextViewExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 07/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

public extension UITextView {
    
    var visibleText: String? {
        guard let start = closestPosition(to: contentOffset),
            let end = characterRange(at: CGPoint(x: contentOffset.x + bounds.maxX, y: contentOffset.y + bounds.maxY))?.end,
            let range = self.textRange(from: start, to: end)
            else { return nil }
        
        return self.text(in: range)
    }
}
