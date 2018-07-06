//
//  ImageAsset.swift
//  Photobook
//
//  Created by Jaime Landazuri on 26/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Image resource based on a UIImage that can be used in a photo book
class ImageAsset: Asset {
    
    /// Image representation of the asset
    var image: UIImage?
    
    /// Date associated with this asset
    var date: Date? = nil
    
    var identifier: String! = UUID().uuidString
    var albumIdentifier: String? = nil
    var uploadUrl: String?
    var size: CGSize { return image?.size ?? .zero }

    /// Init
    ///
    /// - Parameters:
    ///   - image: Image representation of the asset
    ///   - date: Associated date
    init(image: UIImage, date: Date? = nil) {
        self.image = image
        self.date = date
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier, albumIdentifier, image, date, uploadUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        
        if uploadUrl == nil, let image = image {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
            try container.encode(imageData, forKey: .image)
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try values.decode(String.self, forKey: .identifier)
        if let imageData = try values.decodeIfPresent(Data.self, forKey: .image) {
            image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as! UIImage?
        }
        
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
    }

    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        completionHandler(image, nil)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        // Edge case when the asset has been saved an a URL already exists. This method should not be needed in that situation.
        guard let image = image else {
            completionHandler(nil, .jpg, nil)
            return
        }
        let data = UIImageJPEGRepresentation(image, 0.8)
        completionHandler(data, .jpg, nil)
    }
}
