//
//  PhotosAssetMock.swift
//  Photobook
//
//  Created by Jaime Landazuri on 01/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos

// Photos asset subclass with stubs to be used in testing
class PhotosAssetMock: PhotosAsset {
    private var stubSize = CGSize(width: 3000.0, height: 2000.0)
    var height: CGFloat = 2000.0
    
    var identifierStub: String! = "PhotosAssetID"
    
    override var identifier: String! {
        get { return identifierStub }
        set {}
    }
    override var size: CGSize { return stubSize }
    
    var imageStub: UIImage?
    var imageDataStub: Data?
    var imageExtension: AssetDataFileExtension = .jpg
    var error: Error?
    
    init(_ asset: PHAsset = PHAsset(), size: CGSize? = nil) {
        super.init(asset, albumIdentifier: "album")
        if let size = size {
            stubSize = size
        }
    }

    enum CodingKeys: String, CodingKey {
        case identifierStub, stubSize
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifierStub, forKey: .identifierStub)
        try container.encode(stubSize, forKey: .stubSize)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        identifierStub = try values.decode(String.self, forKey: .identifierStub)
        stubSize = try values.decode(CGSize.self, forKey: .stubSize)
    }
    
    override func image(size: CGSize, loadThumbnailFirst: Bool = false, progressHandler: ((Int64, Int64) -> Void)? = nil, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        if imageStub != nil || error != nil {
            completionHandler(imageStub, error)
            return
        }
        super.image(size: size, loadThumbnailFirst: loadThumbnailFirst, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    override func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        if imageDataStub != nil || error != nil {
            completionHandler(imageDataStub, imageExtension, error)
            return
        }
        super.imageData(progressHandler: progressHandler, completionHandler: completionHandler)
    }
}

extension PhotosAssetMock {
    @objc func value(forKey key: String) -> Any? {
        switch key {
        case "uploadUrl":
            return uploadUrl
        default:
            return nil
        }
    }
}
