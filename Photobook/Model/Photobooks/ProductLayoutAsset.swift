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
        case transform, containerSize
        case assetIdentifier, remoteUrl, assetType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transform, forKey: .transform)
        try container.encode(containerSize, forKey: .containerSize)
        try container.encode(asset?.identifier, forKey: .assetIdentifier)
        try container.encode(asset?.uploadUrl, forKey: .remoteUrl)
        try container.encode(asset?.assetType, forKey: .assetType)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        transform = try values.decode(CGAffineTransform.self, forKey: .transform)
        containerSize = try values.decode(CGSize.self, forKey: .containerSize)
        
        let assetType = try values.decode(String.self, forKey: .assetType)
        let assetIdentifier = try values.decode(String.self, forKey: .assetIdentifier)
        let remoteUrl = try? values.decode(String.self, forKey: .remoteUrl)
        
        if assetType == "Photobook.PhotosAsset" {
            // For tests, we use a subclass with some stubs
            if NSClassFromString("XCTest") != nil {
                asset = TestPhotosAsset()
            } else {
                asset = PhotosAsset()
                asset!.identifier = assetIdentifier
                asset!.uploadUrl = remoteUrl
            }
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
}

