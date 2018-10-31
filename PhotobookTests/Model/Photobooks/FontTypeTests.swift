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

import XCTest
import Photos
@testable import Photobook

class FontTypeTests: XCTestCase {
    
    func testTypingAttributes() {
        let fontType: FontType = .plain
        let attributes = fontType.typingAttributes(fontSize: 9.0, fontColor: .red)
        
        let font = attributes[NSAttributedString.Key.font] as? UIFont
        let color = attributes[NSAttributedString.Key.foregroundColor] as? UIColor
        XCTAssertTrue(font != nil && font!.pointSize == 9.0)
        XCTAssertTrue(color == UIColor.red)
    }
    
    func testTypingAttributes_shouldAlignCenterForSpineText() {
        let fontType: FontType = .plain
        let attributes = fontType.typingAttributes(fontSize: 10.0, fontColor: .black, isSpineText: true)
        
        let paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle
        XCTAssertTrue(paragraphStyle != nil && paragraphStyle?.alignment == .center)
    }
    
    func testAttributedText() {
        let fontType: FontType = .plain
        let text = "Text on my page"
        let fontSize: CGFloat = 10.0
        let attributedText = fontType.attributedText(with: text, fontSize: fontSize, fontColor: .blue)
        
        var range = NSRange(location: 0, length: attributedText.length)
        let font = attributedText.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: &range) as? UIFont
        let color = attributedText.attribute(NSAttributedString.Key.foregroundColor, at: 0, effectiveRange: &range) as? UIColor
        XCTAssertEqual(attributedText.string, text)
        XCTAssertEqualOptional(font?.pointSize, 10.0)
        XCTAssertEqualOptional(color, .blue)
    }
    
    func testSizeForScreenRatio_shouldReturnPhotobookFontSize() {
        let inputs = [
            (FontType.plain, CGFloat(8.0)),
            (FontType.classic, CGFloat(11.0)),
            (FontType.solid, CGFloat(13.0))
        ]
        
        for input in inputs {
            let fontType = input.0
            let fontSize = fontType.sizeForScreenToPageRatio()
            XCTAssertEqual(fontSize, input.1, "Incorrect font size for type \(fontType)")
        }
    }
    
    func testSizeForScreenRatio_shouldReturnScaledPhotobookFontSize() {
        let inputs = [
            (FontType.plain, CGFloat(2.22)),
            (FontType.classic, CGFloat(3.06)),
            (FontType.solid, CGFloat(3.61))
        ]
        
        let ratio: CGFloat = 100.0 / 360.0 // Height on screen is 100pt, original page height 360pt
        for input in inputs {
            let fontType = input.0
            let fontSize = fontType.sizeForScreenToPageRatio(ratio)
            XCTAssertTrue(fontSize ==~ input.1, "Incorrect font size for type \(fontType)")
        }
    }
}
