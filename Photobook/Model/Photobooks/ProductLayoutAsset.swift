//
//  ProductLayoutAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 24/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

// A photo item in the user's photobook assigned to a layout box
class ProductLayoutAsset: Codable {
    
    var transform = CGAffineTransform.identity

    // Should be set to true before assigning a new container size if the layout has changed.
    var shouldFitAsset: Bool = false
    
    var containerSize: CGSize! {
        didSet {
            guard !shouldFitAsset && oldValue != nil else {
                fitAssetToContainer()
                return
            }

            let relativeWidth = containerSize.width / oldValue.width
            let relativeHeight = containerSize.height / oldValue.height

            transform = LayoutUtils.adjustTransform(transform, byFactorX: relativeWidth, factorY: relativeHeight)
            adjustTransform()
        }
    }
    
    var asset: Asset? {
        didSet {
            currentImage = nil
            currentIdentifier = nil
            fitAssetToContainer()
        }
    }

    /// Identifier for the asset linked to currentImage
    var currentIdentifier: String?
    
    /// Already loaded image resource
    var currentImage: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case transform, containerSize, asset
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transform, forKey: .transform)
        try container.encode(containerSize, forKey: .containerSize)

        var data: Data? = nil
        if let asset = asset as? PhotosAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = asset as? URLAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = asset as? ImageAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = asset as? PhotosAssetMock {
            data = try PropertyListEncoder().encode(asset)
        }
        try container.encode(data, forKey: .asset)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        transform = try values.decode(CGAffineTransform.self, forKey: .transform)
        containerSize = try values.decodeIfPresent(CGSize.self, forKey: .containerSize)

        if let data = try values.decodeIfPresent(Data.self, forKey: .asset) {
            if let loadedAsset = try? PropertyListDecoder().decode(URLAsset.self, from: data) {
                asset = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode(ImageAsset.self, from: data) {
                asset = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode(PhotosAsset.self, from: data) { // Keep the PhotosAsset case last because otherwise it triggers NSPhotoLibraryUsageDescription crash if not present, which might not be needed
                asset = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode(PhotosAssetMock.self, from: data) {
                asset = loadedAsset
            }
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
        aLayoutAsset.currentImage = currentImage
        aLayoutAsset.currentIdentifier = currentIdentifier
        return aLayoutAsset
    }
}

