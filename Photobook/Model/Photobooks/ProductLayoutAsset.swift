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
    
    var transform = CGAffineTransform.identity

    var containerSize: CGSize! {
        didSet {
            if transform == .identity {
                fitAssetToContainer()
                return
            }
            
            // The asset was assigned a different layout. Fit the asset keeping the user's edits.
            adjustTransform()
        }
    }
    
    var asset: Asset? {
        didSet {
            fitAssetToContainer()
        }
    }
    
    func adjustTransform() {
        guard let asset = asset else { return }
        
        transform = LayoutUtils.adjustTransform(transform, forViewSize: asset.size, inContainerSize: containerSize)
    }
    
    private func fitAssetToContainer() {
        guard let asset = asset, let containerSize = containerSize else { return }
        
        // Calculate scale
        // Match largest dimension in the container. Rescale with other dimension if the aspect ratio is higher.
        // Ignore any previous translation or rotation
        let scale = LayoutUtils.scaleFactorToFill(containerSize: containerSize, withSize: asset.size, atAngle: 0.0)
        transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
    }
}
