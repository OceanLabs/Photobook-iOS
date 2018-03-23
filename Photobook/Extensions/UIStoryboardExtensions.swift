//
//  UIStoryboardExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

internal extension UIStoryboard {
    
    static func photobookStoryBoard(name: String) -> UIStoryboard {
        return UIStoryboard.init(name: name, bundle: Bundle.photobookBundle())
    }
    
}
