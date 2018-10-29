//
//  CustomAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 19/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

@objc public protocol AssetDataSource: NSCoding {
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void)
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void)
}

class CustomAsset: Asset {
    var dataSource: AssetDataSource
    
    var identifier: String! = UUID().uuidString
    
    var albumIdentifier: String? = nil
    
    var size: CGSize
    
    var date: Date?
    
    var uploadUrl: String?
    
    init(dataSource: AssetDataSource, size: CGSize, date: Date? = nil) {
        self.dataSource = dataSource
        self.size = size
        self.date = date
    }
    
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        dataSource.image(size: size, loadThumbnailFirst: loadThumbnailFirst, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        dataSource.imageData(progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    enum CodingKeys: String, CodingKey {
        case imageIdentifier, albumIdentifier, dataSource, size, date, uploadUrl
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try values.decode(String.self, forKey: .imageIdentifier)
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
        size = try values.decode(CGSize.self, forKey: .size)
        
        let dataSourceData = try values.decode(Data.self, forKey: .dataSource)
        dataSource = NSKeyedUnarchiver.unarchiveObject(with: dataSourceData) as! AssetDataSource
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .imageIdentifier)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
        try container.encode(date, forKey: .date)
        try container.encode(size, forKey: .size)
        try container.encode(NSKeyedArchiver.archivedData(withRootObject: dataSource), forKey: .dataSource)
    }
}
