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

@objc enum FontType: Int, Codable {
    case plain, classic, solid
    
    var fontFamily: String {
        get {
            switch self {
            case .plain: return "OpenSans-Regular"
            case .classic: return "Lora-Regular"
            case .solid: return "Montserrat-Bold"
            }
        }
    }
    
    var photobookFontSize: CGFloat {
        switch self {
        case .plain: return 13.0
        case .classic: return 13.0
        case .solid: return 15.0
        }
    }
    
    var lineHeight: CGFloat {
        switch self {
        case .plain: return 1.25
        case .classic: return 1.27
        case .solid: return 1.23
        }
    }

    private func fontWithSize(_ size: CGFloat) -> UIFont {
        return UIFont(name: fontFamily, size: size)!
    }
    
    func paragraphStyle(isSpineText: Bool) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        
        if isSpineText {
            paragraphStyle.alignment = .center
        } else {
            paragraphStyle.lineHeightMultiple = lineHeight
        }

        return paragraphStyle.copy() as! NSParagraphStyle
    }
    
    /// Typing attributes for a photobook input field
    ///
    /// - Parameters:
    ///   - fontSize: Font size for the input text
    ///   - fontColor: Font colour for the input text
    ///   - isSpineText: Whether the text will show on the spine of the book
    /// - Returns: Typing attributes using the provided parameters
    func typingAttributes(fontSize: CGFloat, fontColor: UIColor, isSpineText: Bool = false) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = self.paragraphStyle(isSpineText: isSpineText)
        let font = fontWithSize(fontSize)
        return [ NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.paragraphStyle: paragraphStyle ]
    }
    
    /// Attributed text to show on a photobook page or spine
    ///
    /// - Parameters:
    ///   - text: The plain text to use
    ///   - fontSize: Font size for the text
    ///   - fontColor: Font colour for the text
    ///   - isSpineText: Whether the text will show on the spine of the book
    /// - Returns: Attributed text using the provided parameters
    func attributedText(with text: String!, fontSize: CGFloat, fontColor: UIColor, isSpineText: Bool = false) -> NSAttributedString {
        let paragraphStyle = self.paragraphStyle(isSpineText: isSpineText)
        let font = fontWithSize(fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [ NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: fontColor, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// Font size for the specified screen to page height ratio
    ///
    /// - Parameters:
    ///   - screenToPageRatio: The relation between screen height and page height: i.e. screen / page
    /// - Returns: The scaled font size. If a ratio is not provided, it returns the original font size.
    func sizeForScreenToPageRatio(_ screenToPageRatio: CGFloat? = nil) -> CGFloat {
        let photobookToOnScreenScale = screenToPageRatio != nil ? screenToPageRatio! : 1.0
        return photobookFontSize * photobookToOnScreenScale
    }
}

/// Values for Photobook API
extension FontType {
    var apiFontFamily: String {
        switch self {
        case .plain: return "\'Open Sans\', sans-serif"
        case .classic: return "Lora, serif"
        case .solid: return "Montserrat, sans-serif"
        }
    }
    
    var apiPhotobookFontWeight: CGFloat {
        switch self {
        case .plain: return 400
        case .classic: return 400
        case .solid: return 700
        }
    }
    
    var apiPhotobookFontSize: String {
        return "\(photobookFontSize)pt"
    }
}
