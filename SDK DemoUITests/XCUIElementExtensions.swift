//
//  XCUIElementExtensions.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 24/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

extension XCUIElement {
    
    func clearTextField() {
        guard let text = value as? String else {
            XCTFail("Not a text field")
            return
        }
        
        var deleteText = ""
        for _ in 0..<text.count {
            deleteText.append(XCUIKeyboardKey.delete.rawValue)
        }
        
        typeText(deleteText)
    }
    
}
