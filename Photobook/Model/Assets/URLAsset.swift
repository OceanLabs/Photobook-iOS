//
//  URLAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import SDWebImage

struct URLAssetMetadata: Codable {
    var size: CGSize
    let url: URL
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
    
    var assetType: String {
        return NSStringFromClass(URLAsset.self)
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
            completionHandler(nil, ErrorMessage(message: CommonLocalizedStrings.somethingWentWrong))
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
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension?, Error?) -> Void) {
        guard let url = metadata.last?.url else {
            completionHandler(nil, nil, ErrorMessage(message: CommonLocalizedStrings.somethingWentWrong))
            return
        }
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { _, data, error, _, _, _ in
            completionHandler(data, .jpg, error)
        })
    }
    
    enum CodingKeys: String, CodingKey {
        case metadata, identifier, uploadUrl, date, albumIdentifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        metadata = try values.decode([URLAssetMetadata].self, forKey: .metadata)
        identifier = try values.decodeIfPresent(String.self, forKey: .identifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
        albumIdentifier = try values.decode(String.self, forKey: .albumIdentifier)
    }
    
}
