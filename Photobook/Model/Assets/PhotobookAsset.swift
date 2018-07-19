//
//  PhotobookAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 05/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos

/// Represents a photo to be used in a photo book
@objc public final class PhotobookAsset: NSObject {
    
    var asset: Asset
    init?(asset: Asset?) {
        guard asset != nil else { return nil }
        self.asset = asset!
    }
    
    @objc public var uploadUrl: String? {
        return asset.uploadUrl
    }
    
    static func photobookAssets(with assets: [Asset]?) -> [PhotobookAsset]? {
        guard let assets = assets else { return nil }
        guard !assets.isEmpty else { return [PhotobookAsset]()}
        return assets.map { PhotobookAsset(asset: $0)! }
    }
    
    static func assets(from photobookAssets: [PhotobookAsset]?) -> [Asset]? {
        guard let photobookAssets = photobookAssets else { return nil }
        guard !photobookAssets.isEmpty else { return [Asset]() }
        return photobookAssets.map { $0.asset }
    }
    
    /// Creates a PhotobookAsset using a Photos Library asset
    ///
    /// - Parameters:
    ///   - phAsset: The Photo Library asset to use
    ///   - albumIdentifier: Identifier for the album where the asset is included
    @objc public convenience init(withPHAsset phAsset: PHAsset, albumIdentifier: String) {
        self.init(asset: PhotosAsset.init(phAsset, albumIdentifier: albumIdentifier))!
    }
    
    /// Creates a PhotobookAsset using a remote resource
    ///
    /// - Parameters:
    ///   - urlImages: Associated URLs and sizes for the resource
    ///   - identifier: Identifier to use
    ///   - albumIdentifier: Identifier for the album where the asset is included
    ///   - date: Date for the PhotobookAsset
    @objc public convenience init?(withUrlImages urlImages: [URLAssetImage], identifier: String, albumIdentifier: String? = nil, date: Date? = nil) {
        self.init(asset: URLAsset(identifier: identifier, images: urlImages, albumIdentifier: albumIdentifier, date: date))
    }
    
    /// Creates a PhotobookAsset using a single URL
    ///
    /// - Parameters:
    ///   - url: The location of the photo
    ///   - size: Size of the photo
    @objc public convenience init(withUrl url: URL, size: CGSize) {
        self.init(asset: URLAsset(url, size: size))!
    }
    
    /// Creates a PhotobookAsset using a UIImage
    ///
    /// - Parameters:
    ///   - image: The UIImage to use
    ///   - date: Date for the PhotobookAsset
    @objc public convenience init(withImage image: UIImage, date: Date? = nil) {
        self.init(asset: ImageAsset(image: image, date: date))!
    }
}
