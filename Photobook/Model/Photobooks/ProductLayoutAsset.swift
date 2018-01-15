//
//  ProductLayoutAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit
import Photos

// A photo item in the user's photobook assigned to a layout box
class ProductLayoutAsset: Codable {
    
    var transform = CGAffineTransform.identity

    var containerSize: CGSize! {
        didSet {
            if oldValue != nil {
                let oldRatio = oldValue.width / oldValue.height
                let newRatio = containerSize.width / containerSize.height
            
                // Check if we have the same layout
                if abs(oldRatio - newRatio) < CGFloat.minPrecision {
                    // Scales in both axes should be the same
                    let relativeScale = containerSize.width / oldValue.width

                    transform = LayoutUtils.adjustTransform(transform, byFactor: relativeScale)
                    return
                }
            }
            
            if transform == .identity {
                fitAssetToContainer()
                return
            }
            
            // The asset was assigned a different layout. Scale the image down to force a fit to container effect.
            transform = transform.scaledBy(x: 0.001, y: 0.001)
            adjustTransform()
        }
    }
    
    var asset: Asset? {
        didSet {
            fitAssetToContainer()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case transform, containerSize, asset
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transform, forKey: .transform)
        try container.encode(containerSize, forKey: .containerSize)
        
        if let asset = asset as? PhotosAsset {
            try container.encode(asset, forKey: .asset)
        }
        else if let asset = asset as? TestPhotosAsset {
            try container.encode(asset, forKey: .asset)
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        transform = try values.decode(CGAffineTransform.self, forKey: .transform)
        containerSize = try values.decodeIfPresent(CGSize.self, forKey: .containerSize)
        
        if let loadedAsset = try? values.decodeIfPresent(PhotosAsset.self, forKey: .asset) {
            asset = loadedAsset
        }
        else if let loadedAsset = try? values.decodeIfPresent(TestPhotosAsset.self, forKey: .asset) {
            asset = loadedAsset
        }
        else {
            asset = PlaceholderAsset()
        }
    }
    
    func adjustTransform() {
        guard let asset = asset else { return }
        
        transform = LayoutUtils.adjustTransform(transform, forViewSize: asset.size, inContainerSize: containerSize)
    }
    
    private func fitAssetToContainer() {
        guard let asset = asset, let containerSize = containerSize else { return }
        
        // Calculate scale. Ignore any previous translation or rotation
        let scale = LayoutUtils.scaleToFill(containerSize: containerSize, withSize: asset.size, atAngle: 0.0)
        transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
    }
    
    func shallowCopy() -> ProductLayoutAsset {
        let aLayoutAsset = ProductLayoutAsset()
        aLayoutAsset.asset = asset
        aLayoutAsset.containerSize = containerSize
        aLayoutAsset.transform = transform
        return aLayoutAsset
    }
}

