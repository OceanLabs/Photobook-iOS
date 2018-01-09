//
//  PlaceholderAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 23/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PlaceholderAsset: Asset {
    var albumIdentifier = ""
    
    var uploadUrl: String?
    
    var assetType: String = NSStringFromClass(PlaceholderAsset.self)
    
    var size: CGSize = .zero
    
    var isLandscape = false
    
    var identifier: String! = ""
    
    func uneditedImage(size: CGSize, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let image = UIImage(named: "placeholder")
            completionHandler(image, nil)
        }
    }
    
}
