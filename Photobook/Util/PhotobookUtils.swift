//
//  PhotobookUtils.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookUtils: NSObject {
    
    static func photobookStoryBoard(name: String) -> UIStoryboard {
        return UIStoryboard.init(name: name, bundle: photobookBundle())
    }
    
    static func photobookBundle() -> Bundle {
        return Bundle(for: Photobook.self)
    }

}
