//
//  FontTypeTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 23/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
import Photos
@testable import Photobook

class FontTypeTests: XCTestCase {
    
    func testTypingAttributes() {
        let fontType: FontType = .plain
        let attributes = fontType.typingAttributes(fontSize: 9.0, fontColor: .red)
        
        let font = attributes[NSAttributedStringKey.font.rawValue] as? UIFont
        let color = attributes[NSAttributedStringKey.foregroundColor.rawValue] as? UIColor
        XCTAssertTrue(font != nil && font!.pointSize == 9.0)
        XCTAssertTrue(color == UIColor.red)
    }
    
    func testTypingAttributes_shouldAlignCenterForSpineText() {
        let fontType: FontType = .plain
        let attributes = fontType.typingAttributes(fontSize: 10.0, fontColor: .black, isSpineText: true)
        
        let paragraphStyle = attributes[NSAttributedStringKey.paragraphStyle.rawValue] as? NSParagraphStyle
        XCTAssertTrue(paragraphStyle != nil && paragraphStyle?.alignment == .center)
    }
    
    func testAttributedText() {
        let fontType: FontType = .plain
        let text = "Text on my page"
        let fontSize: CGFloat = 10.0
        let attributedText = fontType.attributedText(with: text, fontSize: fontSize, fontColor: .blue)
        
        var range = NSRange(location: 0, length: attributedText.length)
        let font = attributedText.attribute(NSAttributedStringKey.font, at: 0, effectiveRange: &range) as? UIFont
        let color = attributedText.attribute(NSAttributedStringKey.foregroundColor, at: 0, effectiveRange: &range) as? UIColor
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
