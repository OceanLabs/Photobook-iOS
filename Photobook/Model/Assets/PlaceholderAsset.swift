//
//  PlaceholderAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 23/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PlaceholderAsset: Asset {
    var identifier: String = UUID().uuidString
    
    func uneditedImage(size: CGSize, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        completionHandler(UIImage(named: "placeholder"), nil)
    }
    

}
