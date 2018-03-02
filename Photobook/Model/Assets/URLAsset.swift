//
//  URLAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

class URLAsset: Asset {
    
    init(thumbnailUrl: URL? = nil, fullResolutionUrl: URL, albumIdentifier: String, thumbnailSize: CGSize = .zero, size: CGSize = .zero, identifier: String) {
        self.thumbnailUrl = thumbnailUrl
        self.fullResolutionUrl = fullResolutionUrl
        self.albumIdentifier = albumIdentifier
        self.thumbnailSize = thumbnailSize
        self.size = size
        self.identifier = identifier
    }
    
    let thumbnailUrl: URL?
    let fullResolutionUrl: URL
    var identifier: String!
    var thumbnailSize: CGSize
    var size: CGSize
    var uploadUrl: String?
    
    var isLandscape: Bool {
        return self.size.width > self.size.height
    }
    
    var assetType: String {
        return NSStringFromClass(URLAsset.self)
    }
    
    var date: Date?
    
    var albumIdentifier: String
    
    func image(size: CGSize, loadThumbnailsFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // Convert points to pixels
        let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        
        // Ignore loadThumbnailsFirst. Since we are doing a network request for both thumnbails and the full resolution, there's no benefit to getting the thumbnail first
        let url = imageSize.width <= thumbnailSize.width ? thumbnailUrl : fullResolutionUrl
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { image, _, error, _, _, _ in
            DispatchQueue.main.async {
                completionHandler(image, error)
            }
        })
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension?, Error?) -> Void) {
        SDWebImageManager.shared().loadImage(with: fullResolutionUrl, options: [], progress: nil, completed: { _, data, error, _, _, _ in
            completionHandler(data, .jpg, error)
        })
    }
    
}
