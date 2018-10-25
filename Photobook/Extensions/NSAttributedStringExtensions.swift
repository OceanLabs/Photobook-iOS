//
//  NSAttributedStringExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 31/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    /// Initialises an attributed string from HTML text
    ///
    /// - Parameters:
    ///   - html: Text in html format. Suited for simple tags
    ///   - style: Style to apply to the whole text body
    convenience init?(html: String, style: String? = nil) {
        var html = html
        if let style = style {
            html = "<html><body style=\"\(style)\">\(html)</body></html>"
        }
        
        guard let data = html.data(using: .utf8, allowLossyConversion: false) else { return nil }
        guard let attributedString = try? NSAttributedString(data: data,
                                                             options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                                                             documentAttributes: nil) else {
                                                                return nil
        }
        
        self.init(attributedString: attributedString)
    }

    func height(for width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: self)
        let container = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        container.lineFragmentPadding = 0.0
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        
        return layoutManager.usedRect(for: container).height
    }    
}
