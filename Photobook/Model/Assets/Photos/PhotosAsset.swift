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
@objc public class PhotosAsset: NSObject, NSCoding, Asset {
    
    /// Photo library asset
    @objc internal(set) public var photosAsset: PHAsset {
        didSet {
            identifier = photosAsset.localIdentifier
        }
    }
    
    /// Identifier for the album where the asset is included
    @objc internal(set) public var albumIdentifier: String?
    
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
    @objc public init(_ photosAsset: PHAsset, albumIdentifier: String?) {
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
        DispatchQueue.global(qos: .background).async {
            self.imageManager.requestImage(for: self.photosAsset, targetSize: imageSize, contentMode: .aspectFill, options: options) { (image, _) in
                DispatchQueue.main.async {
                    completionHandler(image, nil)
                }
            }
        }
    }
    
    func imageData(progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (Data?, AssetDataFileExtension, Error?) -> Void) {
        
        if photosAsset.mediaType != .image {
            completionHandler(nil, .unsupported, AssetLoadingException.notFound)
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImageData(for: photosAsset, options: options, resultHandler: { imageData, dataUti, _, _ in
            guard let data = imageData, let dataUti = dataUti else {
                completionHandler(nil, .unsupported, AssetLoadingException.notFound)
                return
            }
            
            guard let fileExtensionString = NSURL(fileURLWithPath: dataUti).pathExtension else {
                completionHandler(nil, .unsupported, AssetLoadingException.unsupported)
                return
            }
            
            let fileExtension = AssetDataFileExtension(string: fileExtensionString)
            
            // Check that the image is either jpg, png or gif otherwise convert it to jpg. So no HEICs, TIFFs or RAWs get uploaded to the back end.
            if fileExtension == .unsupported {
                guard let ciImage = CIImage(data: data),
                    let jpegData = CIContext().jpegRepresentation(of: ciImage, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [kCGImageDestinationLossyCompressionQuality : 0.8])
                else {
                    completionHandler(nil, .unsupported, AssetLoadingException.unsupported)
                    return
                }
                completionHandler(jpegData, .jpg, nil)
            } else {
                completionHandler(imageData, fileExtension, nil)
            }
        })
    }
        
    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(albumIdentifier, forKey: "albumIdentifier")
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(uploadUrl, forKey: "uploadUrl")
    }
    
    @objc public required convenience init?(coder aDecoder: NSCoder) {
        guard let assetId = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
              let albumIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "albumIdentifier") as String?,
              let asset = PhotosAsset.assetManager.fetchAsset(withLocalIdentifier: assetId, options: nil) else
            { return nil }
            
        self.init(asset, albumIdentifier: albumIdentifier)
        uploadUrl = aDecoder.decodeObject(of: NSString.self, forKey: "uploadUrl") as String?
    }
    
    static func photosAssets(from assets:[Asset]) -> [PHAsset] {
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
    
    @objc public func wasRemoved(in changeInstance: PHChange) -> Bool {
        if let changeDetails = changeInstance.changeDetails(for: photosAsset),
            changeDetails.objectWasDeleted {
            return true
        }
        return false
    }
}
