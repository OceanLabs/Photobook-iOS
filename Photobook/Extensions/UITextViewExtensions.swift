//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

extension UITextView {
    
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
