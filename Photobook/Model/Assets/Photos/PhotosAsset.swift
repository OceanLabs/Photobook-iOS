//
//  PhotosAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

protocol AssetManager {
    func fetchAsset(withLocalIdentifier identifier: String, options: PHFetchOptions?) -> PHAsset?
    func fetchAssets(in: PHAssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset>
}

class DefaultAssetManager: AssetManager {
    func fetchAsset(withLocalIdentifier identifier: String, options: PHFetchOptions?) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: options).firstObject
    }
    
    func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(in: assetCollection, options: options)
    }
}

/// Photo library resource that can be used in a Photobook
class PhotosAsset: Asset {
    
    /// Photo library asset
    var photosAsset: PHAsset {
        didSet {
            identifier = photosAsset.localIdentifier
        }
    }
    
    /// Identifier for the album where the asset is included
    var albumIdentifier: String?
    
    var imageManager = PHImageManager.default()
    static var assetManager: AssetManager = DefaultAssetManager()
    
    var identifier: String! {
        didSet {
            if photosAsset.localIdentifier != identifier,
               let asset = PhotosAsset.assetManager.fetchAsset(withLocalIdentifier: identifier, options: PHFetchOptions()) {
                    photosAsset = asset
            }
        }
    }
    
    var date: Date? {
        return photosAsset.creationDate
    }

    var size: CGSize { return CGSize(width: photosAsset.pixelWidth, height: photosAsset.pixelHeight) }
    var uploadUrl: String?
    
    /// Init
    ///
    /// - Parameters:
    ///   - photosAsset: Photo library asset
    ///   - albumIdentifier: Identifier for the album where the asset is included
    init(_ photosAsset: PHAsset, albumIdentifier: String?) {
        self.photosAsset = photosAsset
        self.albumIdentifier = albumIdentifier
        identifier = photosAsset.localIdentifier
    }
    
    func image(size: CGSize, loadThumbnailFirst: Bool = true, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // Request the image at the correct aspect ratio
        var imageSize = self.size.resizeAspectFill(size)
        
        let options = PHImageRequestOptions()
        options.deliveryMode = loadThumbnailFirst ? .opportunistic : .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        
        // Convert points to pixels
        imageSize = CGSize(width: imageSize.width * UIScreen.main.usableScreenScale(), height: imageSize.height * UIScreen.main.usableScreenScale())
        DispatchQueue.global(qos: .default).async {
            self.imageManager.requestImage(for: self.photosAsset, targetSize: imageSize, contentMode: .aspectFill, options: options) { (image, _) in
                DispatchQueue.main.async {
                    completionHandler(image, nil)
                }
            }
        }
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        
        if photosAsset.mediaType != .image {
            completionHandler(nil, .unsupported, AssetLoadingException.unsupported(details: "Photos imageData: Not an image type"))
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImageData(for: photosAsset, options: options, resultHandler: { imageData, dataUti, _, info in
            let error = info?[PHImageErrorKey] as? Error
            guard error == nil else {
                completionHandler(nil, .unsupported, error)
                return
            }
            
            guard let data = imageData, let dataUti = dataUti else {
                let details = "Photos imageData: Missing " + (imageData == nil ? "imageData" : "dataUti")
                completionHandler(nil, .unsupported, AssetLoadingException.unsupported(details: details))
                return
            }
            
            guard let fileExtensionString = NSURL(fileURLWithPath: dataUti).pathExtension else {
                completionHandler(nil, .unsupported, AssetLoadingException.unsupported(details: "Photos imageData: Could not determine extension"))
                return
            }
            
            let fileExtension = AssetDataFileExtension(string: fileExtensionString)
            
            // Check that the image is either jpg, png or gif otherwise convert it to jpg. So no HEICs, TIFFs or RAWs get uploaded to the back end.
            if case .unsupported = fileExtension {
                guard let ciImage = CIImage(data: data) else {
                    completionHandler(nil, .unsupported, AssetLoadingException.unsupported(details: "Photos imageData: Could not create CIImage"))
                    return
                }
                
                var tmpJpegData: Data?
                if #available(iOS 10.0, *) {
                    tmpJpegData = CIContext().jpegRepresentation(of: ciImage, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : 0.8])
                } else {
                    tmpJpegData = UIImage(ciImage: ciImage).jpegData(compressionQuality: 0.8)
                }
                
                if let jpegData = tmpJpegData {
                    completionHandler(jpegData, .jpg, nil)
                } else {
                    completionHandler(nil, .unsupported, AssetLoadingException.unsupported(details: "Photos imageData: Could not convert to JPG"))
                }
            } else {
                completionHandler(imageData, fileExtension, nil)
            }
        })
    }
    
    private enum CodingKeys: String, CodingKey {
        case albumIdentifier, identifier, uploadUrl
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(albumIdentifier, forKey: .albumIdentifier)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(uploadUrl, forKey: .uploadUrl)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let assetId = try values.decode(String.self, forKey: .identifier)
        guard let asset = PhotosAsset.assetManager.fetchAsset(withLocalIdentifier: assetId, options: nil) else {
            throw AssetLoadingException.notFound
        }
        
        photosAsset = asset
        identifier = assetId
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)        
    }
    
    static func photosAssets(from assets: [Asset]) -> [PHAsset] {
        var photosAssets = [PHAsset]()
        for asset in assets{
            guard let photosAsset = asset as? PhotosAsset else { continue }
            photosAssets.append(photosAsset.photosAsset)
        }
        
        return photosAssets
    }
    
    static func assets(from photosAssets: [PHAsset], albumId: String) -> [Asset] {
        var assets = [Asset]()
        for photosAsset in photosAssets {
            assets.append(PhotosAsset(photosAsset, albumIdentifier: albumId))
        }
        
        return assets
    }
    
    func wasRemoved(in changeInstance: PHChange) -> Bool {
        if let changeDetails = changeInstance.changeDetails(for: photosAsset),
            changeDetails.objectWasDeleted {
            return true
        }
        return false
    }
}
