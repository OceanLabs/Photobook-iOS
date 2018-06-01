//
//  UITextViewExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 07/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

public extension UITextView {
    
    /// Returns the substring that fits in the UITextView's current bounds
    var visibleText: String? {
        guard let start = closestPosition(to: contentOffset),
            let end = characterRange(at: CGPoint(x: contentOffset.x + bounds.maxX, y: contentOffset.y + bounds.maxY))?.end,
            let range = self.textRange(from: start, to: end)
            else { return nil }
        
        return self.text(in: range)
    }
    
    /// Returns the locations where visual line breaks are as the text wraps around the UITextView bounds
    func lineBreakIndexes() -> [Int]? {
        var index = 0
        var lineRange = NSRange()
        
        var indexes = [Int]()
        
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        while index < numberOfGlyphs {
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            if index < numberOfGlyphs { indexes.append(index) }
        }
        return indexes.count > 0 ? indexes : nil
    }
}
