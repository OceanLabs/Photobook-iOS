//
//  URLAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

/// Location for an image of a specific size
@objc public class URLAssetImage: NSObject, NSCoding {
    
    let size: CGSize
    let url: URL
    
    /// Initialises a URLAssetImage
    ///
    /// - Parameters:
    ///   - url: Location of the image
    ///   - size: Dimensions of the image
    @objc public init(url: URL, size: CGSize) {
        self.size = size
        self.url = url
    }
    
    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(size, forKey: "size")
        aCoder.encode(url, forKey: "url")
    }

    @objc public required convenience init?(coder aDecoder: NSCoder) {
        guard let size = aDecoder.decodeObject(forKey: "size") as? CGSize,
              let url = aDecoder.decodeObject(forKey: "url") as? URL
            else { return nil }
        
        self.init(url: url, size: size)
    }
}

/// Remote image resource that can be used in a photo book
@objc public class URLAsset: NSObject, NSCoding, Asset {
    
    /// Unique identifier
    @objc public var identifier: String!
    
    /// Album unique identifier
    @objc public var albumIdentifier: String?
    
    /// Date associated with this asset
    @objc public var date: Date?
    
    /// Array of URL per size available for the asset
    @objc public var images: [URLAssetImage]
    
    var uploadUrl: String?
    var size: CGSize {
        return images.last?.size ?? .zero
    }
    
    @objc public init(identifier: String, albumIdentifier: String, images: [URLAssetImage]) {
        self.images = images.sorted(by: { $0.size.width < $1.size.width })
        self.albumIdentifier = albumIdentifier
        self.identifier = identifier
    }
    
    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(images, forKey: "images")
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(uploadUrl, forKey: "uploadUrl")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(albumIdentifier, forKey: "albumIdentifier")
    }
    
    @objc public required convenience init?(coder aDecoder: NSCoder) {
        guard let identifier = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
            let albumIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "albumIdentifier") as String?,
            let images = aDecoder.decodeObject(forKey: "images") as? [URLAssetImage]
            else { return nil }
        
        self.init(identifier: identifier,  albumIdentifier: albumIdentifier, images: images)
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
        date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date?
    }
    
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // Convert points to pixels
        var imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        
        // Modify the requested size to match the image aspect ratio
        if let maxSize = images.last?.size, maxSize != .zero {
            imageSize = maxSize.resizeAspectFill(imageSize)
        }
        
        // Find the smallest image that is larger than what we want
        let comparisonClosure: (URLAssetImage) -> Bool = imageSize.width >= imageSize.height ? { $0.size.width >= imageSize.width } : { $0.size.height >= imageSize.height }
        let image = images.first (where: comparisonClosure) ?? images.last
        guard let url = image?.url else {
            completionHandler(nil, ErrorMessage(text: CommonLocalizedStrings.somethingWentWrong))
            return
        }
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { image, _, error, _, _, _ in
            DispatchQueue.global(qos: .background).async {
                let image = image?.shrinkToSize(imageSize)
                DispatchQueue.main.async {
                    completionHandler(image, error)
                }
            }
        })
        
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        guard let url = images.last?.url else {
            completionHandler(nil, .unsupported, ErrorMessage(text: CommonLocalizedStrings.somethingWentWrong))
            return
        }
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { _, data, error, _, _, _ in
            completionHandler(data, .jpg, error)
        })
    }
}
