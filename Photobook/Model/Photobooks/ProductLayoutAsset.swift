//
//  ProductLayoutAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

// A photo item in the user's photobook assigned to a layout box
class ProductLayoutAsset {
    var relativeOrigin = CGPoint.zero
    var scale: CGFloat = 1.0
    var rotation: CGFloat = 0.0

    var containerSize: CGSize! {
        didSet {
            // TODO: Calculate scale considering rotation bounds
        }
    }
    var asset: Asset? {
        didSet {
            guard let asset = asset else { return }
            
            // Reset rotation and scale
            rotation = 0.0
            
            // Calculate scale
            // Match largest dimension in the container. Rescale with other dimension if the aspect ratio is higher.
            if asset.isLandscape {
                scale = containerSize.width / asset.width
                if asset.height * scale < containerSize.height {
                    scale = containerSize.height / asset.height
                }
            } else {
                scale = containerSize.height / asset.height
                if asset.width * scale < containerSize.width {
                    scale = containerSize.width / asset.width
                }
            }
        }
    }
}
