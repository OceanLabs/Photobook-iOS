//
//  URLAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

protocol WebImageManager {
    func loadImage(with url: URL, completion: @escaping (UIImage?, Data?, Error?) -> Void)
}

class DefaultWebImageManager: WebImageManager {
    
    func loadImage(with url: URL, completion: @escaping (UIImage?, Data?, Error?) -> Void) {
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil) { (image, data, error, _, _, _) in
            completion(image, data, error)
        }
    }
}

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
        let stringSize = NSStringFromCGSize(size)
        aCoder.encode(stringSize, forKey: "size")
        aCoder.encode(url, forKey: "url")
    }

    @objc public required convenience init?(coder aDecoder: NSCoder) {
        guard let stringSize = aDecoder.decodeObject(of: NSString.self, forKey: "size") as String?,
              let url = aDecoder.decodeObject(forKey: "url") as? URL
            else { return nil }
        
        self.init(url: url, size: CGSizeFromString(stringSize))
    }
}

/// Remote image resource that can be used in a Photobook
@objc public class URLAsset: NSObject, NSCoding, Asset {
    
    /// Unique identifier
    @objc internal(set) public var identifier: String!
    
    /// Album unique identifier
    @objc internal(set) public var albumIdentifier: String?
    
    /// Date associated with this asset
    @objc internal(set) public var date: Date?
    
    /// Array of URL per size available for the asset
    @objc internal(set) public var images: [URLAssetImage]
    
    var uploadUrl: String?
    var size: CGSize { return images.last!.size }
    
    lazy var webImageManager: WebImageManager = DefaultWebImageManager()
    var screenScale = UIScreen.main.usableScreenScale()
    
    /// Init
    ///
    /// - Parameters:
    ///   - identifier: Identifier for the asset
    ///   - images: Array of sizes and associated URLs
    ///   - albumIdentifier: Identifier for the album the asset belongs to
    ///   - date: Date associated to this asset
    @objc public init?(identifier: String, images: [URLAssetImage], albumIdentifier: String? = nil, date: Date? = nil) {
        guard images.count > 0 else { return nil }
        self.images = images.sorted(by: { $0.size.width < $1.size.width })
        self.identifier = identifier
        self.albumIdentifier = albumIdentifier
        self.date = date
    }
    
    /// Init with only one URL
    ///
    /// - Parameters:
    ///   - url: The URL of the remote image
    ///   - size: The size of the image.
    @objc public convenience init(_ url: URL, size: CGSize) {
        self.init(identifier: url.absoluteString, images: [URLAssetImage(url: url, size: size)])!
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
            let images = aDecoder.decodeObject(forKey: "images") as? [URLAssetImage]
            else { return nil }
        
        let albumIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "albumIdentifier") as String?
        
        self.init(identifier: identifier, images: images, albumIdentifier: albumIdentifier)
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
        date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date?
    }
    
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // Convert points to pixels
        var imageSize = CGSize(width: size.width * screenScale, height: size.height * screenScale)
        
        // Modify the requested size to match the image aspect ratio
        if let maxSize = images.last?.size, maxSize != .zero {
            imageSize = maxSize.resizeAspectFill(imageSize)
        }
        
        // Find the smallest image that is larger than what we want
        let comparisonClosure: (URLAssetImage) -> Bool = imageSize.width >= imageSize.height ? { $0.size.width >= imageSize.width } : { $0.size.height >= imageSize.height }
        let image = images.first (where: comparisonClosure) ?? images.last!
        
        webImageManager.loadImage(with: image.url, completion: { image, _, error in
            DispatchQueue.global(qos: .background).async {
                let image = image?.shrinkToSize(imageSize)
                DispatchQueue.main.async {
                    completionHandler(image, error)
                }
            }
        })
        
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        
        webImageManager.loadImage(with: images.last!.url, completion: { image, data, error in
            var imageData: Data?
            if let image = image {
                imageData = UIImageJPEGRepresentation(image, 1)
            } else if let data = data, UIImage(data: data) != nil {
                imageData = data
            } else {
                completionHandler(nil, .unsupported, ErrorMessage(text: CommonLocalizedStrings.somethingWentWrong))
                return
            }
            completionHandler(imageData, .jpg, error)
        })
    }
}
