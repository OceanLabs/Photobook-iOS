//
//  PhotosAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

// Photos asset subclass with stubs to be used in testing
class TestPhotosAsset: PhotosAsset {
    override var size: CGSize { return CGSize(width: 10.0, height: 20.0) }
    override init(_ asset: PHAsset, albumIdentifier: String) {
        super.init(asset, albumIdentifier: albumIdentifier)
        identifier = "id"
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(PHAsset(), albumIdentifier: "")
        identifier = "id"
    }
}

class PhotosAsset: NSObject, NSCoding, Asset {
    
    var photosAsset: PHAsset {
        didSet {
            identifier = photosAsset.localIdentifier
        }
    }
    
    var identifier: String! {
        didSet {
            if photosAsset.localIdentifier != identifier,
               let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: PHFetchOptions()).firstObject {
                    photosAsset = asset
            }
        }
    }
    
    var date: Date? {
        return photosAsset.creationDate
    }
    
    var albumIdentifier: String?

    var size: CGSize { return CGSize(width: photosAsset.pixelWidth, height: photosAsset.pixelHeight) }
    var uploadUrl: String?
    
    init(_ asset: PHAsset, albumIdentifier: String) {
        photosAsset = asset
        identifier = photosAsset.localIdentifier
        self.albumIdentifier = albumIdentifier
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
            PHImageManager.default().requestImage(for: self.photosAsset, targetSize: imageSize, contentMode: .aspectFill, options: options) { (image, _) in
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
        
        PHImageManager.default().requestImageData(for: photosAsset, options: options, resultHandler: { imageData, dataUti, _, info in
            guard let data = imageData, let dataUti = dataUti else {
                completionHandler(nil, .unsupported, AssetLoadingException.notFound)
                return
            }
            
            let fileExtension: AssetDataFileExtension
            if dataUti.contains(".png") {
                fileExtension = .png
            } else if dataUti.contains(".jpeg") {
                fileExtension = .jpg
            } else if dataUti.contains(".gif") {
                fileExtension = .gif
            } else {
                fileExtension = .unsupported
            }
            
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
        
    func encode(with aCoder: NSCoder) {
        aCoder.encode(albumIdentifier, forKey: "albumIdentifier")
        aCoder.encode(identifier, forKey: "identifier")
        aCoder.encode(uploadUrl, forKey: "uploadUrl")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let assetId = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
              let albumIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: "albumIdentifier") as String?,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject else
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
    
    static func assets(from photosAssets:[PHAsset], albumId: String) -> [Asset] {
        var assets = [Asset]()
        for photosAsset in photosAssets{
            assets.append(PhotosAsset(photosAsset, albumIdentifier: albumId))
        }
        
        return assets
    }
    
}
