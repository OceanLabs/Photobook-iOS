//
//  UIAlertControllerExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 27/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    convenience init(errorMessage: ErrorMessage) {
        self.init(title: errorMessage.title, message: errorMessage.text, preferredStyle: .alert)
        addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
    }
    
}
