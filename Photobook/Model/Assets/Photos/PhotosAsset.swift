//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Photos

@objc public protocol AssetManager {
    func fetchAsset(withLocalIdentifier identifier: String, options: PHFetchOptions?) -> PHAsset?
    func fetchAssets(in: PHAssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset>
}

@objc public class DefaultAssetManager: NSObject, AssetManager {
    public func fetchAsset(withLocalIdentifier identifier: String, options: PHFetchOptions?) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: options).firstObject
    }
    
    public func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(in: assetCollection, options: options)
    }
}

/// Photo library resource that can be used in a Photobook
class PhotosAsset: Asset {
    
    /// Photo library asset
    var photosAsset: PHAsset! {
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

    var size: CGSize {
        guard photosAsset != nil else { return .zero }
        return CGSize(width: photosAsset.pixelWidth, height: photosAsset.pixelHeight)
    }
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
        guard photosAsset != nil else {
            completionHandler(nil, AssetLoadingException.notFound)
            return
        }
        
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
        guard photosAsset != nil else {
            completionHandler(nil, .unsupported, AssetLoadingException.notFound)
            return
        }

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
                
                if let jpegData = CIContext().jpegRepresentation(of: ciImage, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : 0.8]) {
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
        if let asset = PhotosAsset.assetManager.fetchAsset(withLocalIdentifier: assetId, options: nil) {
            photosAsset = asset
        }
        identifier = assetId
        albumIdentifier = try values.decodeIfPresent(String.self, forKey: .albumIdentifier)
        uploadUrl = try values.decodeIfPresent(String.self, forKey: .uploadUrl)        
    }
    
    static func phAssets(from photobookAssets: [PhotobookAsset]) -> [PHAsset] {
        var phAssets = [PHAsset]()
        for photobookAsset in photobookAssets {
            guard let photosAsset = photobookAsset.asset as? PhotosAsset else { continue }
            phAssets.append(photosAsset.photosAsset)
        }
        
        return phAssets
    }
    
    static func assets(from photosAssets: [PHAsset], albumId: String) -> [Asset] {
        var assets = [Asset]()
        for photosAsset in photosAssets {
            assets.append(PhotosAsset(photosAsset, albumIdentifier: albumId))
        }
        
        return assets
    }    
}
