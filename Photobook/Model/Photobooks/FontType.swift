//
//  FontType.swift
//  Photobook
//
//  Created by Jaime Landazuri on 01/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

@objc enum FontType: Int, Codable {
    case plain, classic, solid
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    private func fontWithSize(_ size: CGFloat) -> UIFont {
        let name: String
        switch self {
        case .plain: name = "OpenSans-Regular"
        case .classic: name = "Lora-Regular"
        case .solid: name = "Montserrat-Bold"
        }
        return UIFont(name: name, size: size)!
    }
    
    private func paragraphStyle(isSpineText: Bool) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()

        switch self {
        case .plain: paragraphStyle.lineHeightMultiple = 1.25
        case .classic: paragraphStyle.lineHeightMultiple = 1.27
        case .solid: paragraphStyle.lineHeightMultiple = 1.23
        }
        
        if isSpineText {
            paragraphStyle.alignment = .center
        }

        return paragraphStyle.copy() as! NSParagraphStyle
    }
    
    private func photobookFontSize(isSpineText: Bool) -> CGFloat {
        switch self {
        case .plain: return 8.0
        case .classic: return 11.0
        case .solid: return 13.0
        }
    }
    
    /// Typing attributes for a photobook input field
    ///
    /// - Parameters:
    ///   - fontSize: Font size for the input text
    ///   - fontColor: Font colour for the input text
    ///   - isSpineText: Whether the text will show on the spine of the book
    /// - Returns: Typing attributes using the provided parameters
    func typingAttributes(fontSize: CGFloat, fontColor: UIColor, isSpineText: Bool = false) -> [String: Any] {
        let paragraphStyle = self.paragraphStyle(isSpineText: isSpineText)
        let font = fontWithSize(fontSize)
        return [ NSAttributedStringKey.font.rawValue: font, NSAttributedStringKey.foregroundColor.rawValue: fontColor, NSAttributedStringKey.paragraphStyle.rawValue: paragraphStyle ]
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
        
        let attributes: [NSAttributedStringKey: Any] = [ NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: fontColor, NSAttributedStringKey.paragraphStyle: paragraphStyle]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// Font size for the specified page height on screen in relation to the original book size in points
    ///
    /// - Parameters:
    ///   - screenHeight: The height of the page on screen
    ///   - isSpineText: Whether the text will show on the spine of the book
    /// - Returns: The scaled font size. If screenHeight is not provided, it returns the original font size.
    func sizeForScreenHeight(_ screenHeight: CGFloat? = nil, isSpineText: Bool = false) -> CGFloat {
        let photobookToOnScreenScale = screenHeight != nil ? screenHeight! / product.template.pageHeight : 1.0
        return photobookFontSize(isSpineText: isSpineText) * photobookToOnScreenScale
    }
}
