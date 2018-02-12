//
//  FontType.swift
//  Photobook
//
//  Created by Jaime Landazuri on 01/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

@objc enum FontType: Int, Codable {
    case clear, classic, solid, cover
    
    private func fontWithSize(_ size: CGFloat) -> UIFont {
        let name: String
        switch self {
        case .clear: name = "OpenSans-Regular"
        case .classic: name = "Lora-Regular"
        case .solid: name = "Montserrat-Bold"
        case .cover: name = "OpenSans-Regular"
        }
        return UIFont(name: name, size: size)!
    }
    
    private func paragraphStyle() -> NSParagraphStyle {
        let lineHeightMultiple: CGFloat
        switch self {
        case .clear, .classic, .solid:
            lineHeightMultiple = 1.2
        default:
            lineHeightMultiple = 1.0
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        return paragraphStyle.copy() as! NSParagraphStyle
    }
    
    func photobookFontSize() -> CGFloat {
        switch self {
        case .clear, .classic, .cover: return 14.0
        case .solid: return 16.0
        }
    }
    
    func typingAttributes(fontSize: CGFloat, fontColor: UIColor) -> [String: Any] {
        let paragraphStyle = self.paragraphStyle()
        let font = fontWithSize(fontSize)
        return [ NSAttributedStringKey.font.rawValue: font, NSAttributedStringKey.foregroundColor.rawValue: fontColor, NSAttributedStringKey.paragraphStyle.rawValue: paragraphStyle ]
    }
    
    func attributedText(with text: String!, fontSize: CGFloat, fontColor: UIColor) -> NSAttributedString {
        let paragraphStyle = self.paragraphStyle()
        let font = fontWithSize(fontSize)
        
        let attributes: [NSAttributedStringKey: Any] = [ NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: fontColor, NSAttributedStringKey.paragraphStyle: paragraphStyle]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
