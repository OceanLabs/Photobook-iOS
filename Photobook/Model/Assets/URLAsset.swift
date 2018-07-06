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
@objc public class URLAssetImage: NSObject, NSCoding, Codable {
    
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
class URLAsset: Asset {
    
    /// Unique identifier
    var identifier: String!
    
    /// Album unique identifier
    var albumIdentifier: String?
    
    /// Date associated with this asset
    var date: Date?
    
    /// Array of URL per size available for the asset
    var images: [URLAssetImage]
    
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
    ///   - date: Date associated with this asset
    init?(identifier: String, images: [URLAssetImage], albumIdentifier: String? = nil, date: Date? = nil) {
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
    convenience init(_ url: URL, size: CGSize) {
        self.init(identifier: url.absoluteString, images: [URLAssetImage(url: url, size: size)])!
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier, albumIdentifier, images, date, uploadUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        try container.encode(images, forKey: .images)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        images = try values.decode([URLAssetImage].self, forKey: .images)
        identifier = try values.decode(String.self, forKey: .identifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
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
            DispatchQueue.global(qos: .default).async {
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
