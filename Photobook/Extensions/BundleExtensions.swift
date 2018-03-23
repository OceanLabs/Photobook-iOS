//
//  BundleExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

internal extension Bundle {
    
    static func photobookBundle() -> Bundle {
        return Bundle(for: Photobook.self)
    }
}
