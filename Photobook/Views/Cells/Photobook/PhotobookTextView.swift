//
//  PhotobookTextView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 12/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// UITextView subclass used for editing text on photobooks
class PhotobookTextView: UITextView {
    
    private func textGoesOverBounds(_ string: String, range: NSRange) -> Bool {
        let viewHeight = bounds.height
        let width = textContainer.size.width
        
        let attributedString = NSMutableAttributedString(attributedString: textStorage)
        attributedString.replaceCharacters(in: range, with: string)
        
        let textHeight = (attributedString as NSAttributedString).height(for: width)
        return textHeight >= viewHeight
    }
    
    func shouldChangePhotobookText(in range: NSRange, replacementText text: String) -> Bool {
        // Allow deleting
        if text.count == 0 { return true }
        
        // Disallow pasting non-ascii characters
        if !text.canBeConverted(to: String.Encoding.ascii) { return false }
        
        // Check that the new length doesn't exceed the textView bounds
        return !textGoesOverBounds(text, range: range)
    }
}
