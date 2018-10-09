//
//  NSAttributedStringExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 31/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
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
