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
    
    
    init(imageUrlsPerSize: [(size: CGSize, url: URL)], albumIdentifier: String, thumbnailSize: CGSize = .zero, size: CGSize = .zero, identifier: String) {
        sortedImageUrlsPerSize = imageUrlsPerSize.sorted(by: { $0.size.width > $1.size.width })
        self.albumIdentifier = albumIdentifier
        self.identifier = identifier
    }
    
    
    /// An array of image URL per size, sorted by descending width
    private let sortedImageUrlsPerSize: [(size: CGSize, url: URL)]
    var identifier: String!
    var uploadUrl: String?
    var size: CGSize {
        return sortedImageUrlsPerSize.first?.size ?? .zero
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
        let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        
        // Find the smallest image that is larger than what we want
        var url = sortedImageUrlsPerSize.first?.url
        for pair in sortedImageUrlsPerSize {
            if pair.size.width >= imageSize.width {
                url = pair.url
            } else {
                break
            }
        }
        
        guard url != nil else {
            completionHandler(nil, ErrorMessage(message: CommonLocalizedStrings.somethingWentWrong))
            return
        }
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { image, _, error, _, _, _ in
            DispatchQueue.main.async {
                completionHandler(image, error)
            }
        })
        
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension?, Error?) -> Void) {
        guard let url = sortedImageUrlsPerSize.first?.url else {
            completionHandler(nil, nil, ErrorMessage(message: CommonLocalizedStrings.somethingWentWrong))
            return
        }
        
        SDWebImageManager.shared().loadImage(with: url, options: [], progress: nil, completed: { _, data, error, _, _, _ in
            completionHandler(data, .jpg, error)
        })
    }
    
    enum CodingKeys: String, CodingKey {
        case sortedImageUrlsPerSize, identifier, uploadUrl, date, albumIdentifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sortedImageUrlsPerSize, forKey: .sortedImageUrlsPerSize)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        sortedImageUrlsPerSize = try values.decode([(size: CGSize, url: URL)].self, forKey: .sortedImageUrlsPerSize)
        identifier = try values.decodeIfPresent(String.self, forKey: .identifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
        albumIdentifier = try values.decode(String.self, forKey: .albumIdentifier)
    }
    
}
