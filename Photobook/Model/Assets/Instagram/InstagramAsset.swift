//
//  InstagramAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 16/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

class InstagramAsset: Asset {
    
    private struct Constants {
        static let instagramThumbnailWidth: CGFloat = 150
    }
    
    init(thumbnailUrl: URL, standardResolutionUrl: URL, albumIdentifier: String, size: CGSize, identifier: String) {
        self.thumbnailUrl = thumbnailUrl
        self.standardResolutionUrl = standardResolutionUrl
        self.albumIdentifier = albumIdentifier
        self.size = size
        self.identifier = identifier
    }
    
    let thumbnailUrl: URL
    let standardResolutionUrl: URL
    var identifier: String!
    var size: CGSize
    var uploadUrl: String?
    
    var isLandscape: Bool {
        return self.size.width > self.size.height
    }
    
    var assetType: String {
        return NSStringFromClass(InstagramAsset.self)
    }
    
    var date: Date?
    
    var albumIdentifier: String
    
    func uneditedImage(size: CGSize, loadThumbnailsFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // Convert points to pixels
        let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        
        // Ignore loadThumbnailsFirst. Since we are doing a network request for both thumnbails and the full resolution, there's no benefit to getting the thumbnail first
        let url = imageSize.width <= Constants.instagramThumbnailWidth ? thumbnailUrl : standardResolutionUrl
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { image, _, error, _, _, _ in
            completionHandler(image, error)
        })
    }

}
