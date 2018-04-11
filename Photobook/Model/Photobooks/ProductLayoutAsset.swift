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

    // Should be set to true before assigning a new container size if the layout has changed.
    var shouldFitAsset: Bool = false
    
    var containerSize: CGSize! {
        didSet {
            if !shouldFitAsset && oldValue != nil {
                let relativeScale: CGFloat
                let relativeWidth = containerSize.width / oldValue.width
                if !relativeWidth.isNaN && oldValue.width > 0.0 && containerSize.width >= containerSize.height {
                    relativeScale = relativeWidth
                } else {
                    let relativeHeight = containerSize.height / oldValue.height
                    relativeScale = relativeHeight
                }
                transform = LayoutUtils.adjustTransform(transform, byFactor: relativeScale)
                adjustTransform()
                return
            }            
            fitAssetToContainer()
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
            let assetData = NSKeyedArchiver.archivedData(withRootObject: asset)
            try container.encode(assetData, forKey: .asset)
        } else if let asset = asset as? URLAsset {
            let assetData = NSKeyedArchiver.archivedData(withRootObject: asset)
            try container.encode(assetData, forKey: .asset)

        } else if let asset = asset as? TestPhotosAsset {
            let assetData = NSKeyedArchiver.archivedData(withRootObject: asset)
            try container.encode(assetData, forKey: .asset)
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        transform = try values.decode(CGAffineTransform.self, forKey: .transform)
        containerSize = try values.decodeIfPresent(CGSize.self, forKey: .containerSize)

        if let data = try values.decodeIfPresent(Data.self, forKey: .asset),
            let loadedAsset = NSKeyedUnarchiver.unarchiveObject(with: data) as? Asset {
                asset = loadedAsset
        }
    }
    
    func adjustTransform() {
        guard let asset = asset, let containerSize = containerSize else { return }
        
        transform = LayoutUtils.adjustTransform(transform, forViewSize: asset.size, inContainerSize: containerSize)
    }
    
    func fitAssetToContainer() {
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

