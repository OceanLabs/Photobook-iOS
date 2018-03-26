//
//  URLAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

class URLAssetMetadata: NSObject, NSCoding {
    var size: CGSize
    let url: URL
    
    init(size: CGSize, url: URL) {
        self.size = size
        self.url = url
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let size = aDecoder.decodeObject(forKey: "size") as? CGSize,
              let url = aDecoder.decodeObject(forKey: "url") as? URL
            else { return nil }
        
        self.init(size: size, url: url)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(size, forKey: "size")
        aCoder.encode(url, forKey: "url")
    }
}

class URLAsset: Asset {
    
    init(metadata: [URLAssetMetadata], albumIdentifier: String, thumbnailSize: CGSize = .zero, size: CGSize = .zero, identifier: String) {
        self.metadata = metadata.sorted(by: { $0.size.width < $1.size.width })
        self.albumIdentifier = albumIdentifier
        self.identifier = identifier
    }
    
    
    /// An array of image URL per size, sorted by ascending width
    private let metadata: [URLAssetMetadata]
    var identifier: String!
    var uploadUrl: String?
    var size: CGSize {
        return metadata.last?.size ?? .zero
    }
    
    var isLandscape: Bool {
        return self.size.width > self.size.height
    }
        
    var date: Date?
    
    var albumIdentifier: String
    
    func image(size: CGSize, loadThumbnailsFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // Convert points to pixels
        var imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        
        // Modify the requested size to match the image aspect ratio
        if let maxSize = self.metadata.last?.size, maxSize != .zero {
            imageSize = maxSize.resizeAspectFill(imageSize)
        }
        
        // Find the smallest image that is larger than what we want
        let comparisonClosure: (URLAssetMetadata) -> Bool = imageSize.width >= imageSize.height ? { $0.size.width >= imageSize.width } : { $0.size.height >= imageSize.height }
        let metadata = self.metadata.first (where: comparisonClosure) ?? self.metadata.last
        guard let url = metadata?.url else {
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
        guard let url = metadata.last?.url else {
            completionHandler(nil, .unsupported, ErrorMessage(text: CommonLocalizedStrings.somethingWentWrong))
            return
        }
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { _, data, error, _, _, _ in
            completionHandler(data, .jpg, error)
        })
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(metadata, forKey: "metadata")
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(uploadUrl, forKey: "uploadUrl")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(albumIdentifier, forKey: "albumIdentifier")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let identifier = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
              let albumIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "albumIdentifier") as String?,
              let metadata = aDecoder.decodeObject(forKey: "metadata") as? [URLAssetMetadata]
            else { return nil }
        
        self.init(metadata: metadata, albumIdentifier: albumIdentifier, identifier: identifier)
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
        date = aDecoder.decodeObject(of: NSDate.self, forKey: "date") as Date?
    }
}
