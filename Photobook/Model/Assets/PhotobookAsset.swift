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

/// Represents a photo to be used in a photo book
@objc public final class PhotobookAsset: NSObject, Codable {
    
    var asset: Asset
    init?(asset: Asset?) {
        guard asset != nil else { return nil }
        self.asset = asset!
    }
    
    @objc public var identifier: String { return asset.identifier }
    @objc public var albumIdentifier: String? { return asset.albumIdentifier }
    @objc public var date: Date? { return asset.date }
    @objc public var size: CGSize { return asset.size }
    @objc public var uploadUrl: String? { return asset.uploadUrl }
    @objc public var phAsset: PHAsset? {
        guard let photoAsset = asset as? PhotosAsset else { return nil }
        return photoAsset.photosAsset
    }
    
    static func photobookAssets(with assets: [Asset]?) -> [PhotobookAsset]? {
        guard let assets = assets else { return nil }
        guard !assets.isEmpty else { return [PhotobookAsset]()}
        return assets.map { PhotobookAsset(asset: $0)! }
    }
    
    static func assets(from photobookAssets: [PhotobookAsset]?) -> [Asset]? {
        guard let photobookAssets = photobookAssets else { return nil }
        guard !photobookAssets.isEmpty else { return [Asset]() }
        return photobookAssets.map { $0.asset }
    }
    
    enum CodingKeys: String, CodingKey {
        case asset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data: Data = try asset.data()
        try container.encode(data, forKey: .asset)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let data = try values.decodeIfPresent(Data.self, forKey: .asset) else {
            throw AssetLoadingException.notFound
        }
        let asset = try PhotosAsset.asset(from: data) // PhotosAsset is needed to call the static method in Asset
        self.init(asset: asset)!
    }

    /// Creates a PhotobookAsset using a Photos Library asset
    ///
    /// - Parameters:
    ///   - phAsset: The Photo Library asset to use
    ///   - albumIdentifier: Identifier for the album where the asset is included
    @objc public convenience init(withPHAsset phAsset: PHAsset, albumIdentifier: String) {
        self.init(asset: PhotosAsset.init(phAsset, albumIdentifier: albumIdentifier))!
    }
    
    /// Creates a PhotobookAsset using a remote resource
    ///
    /// - Parameters:
    ///   - urlImages: Associated URLs and sizes for the resource
    ///   - identifier: Identifier to use
    ///   - albumIdentifier: Identifier for the album where the asset is included
    ///   - date: Date for the PhotobookAsset
    @objc public convenience init?(withUrlImages urlImages: [URLAssetImage], identifier: String, albumIdentifier: String? = nil, date: Date? = nil) {
        self.init(asset: URLAsset(identifier: identifier, images: urlImages, albumIdentifier: albumIdentifier, date: date))
    }
    
    /// Creates a PhotobookAsset using a single URL
    ///
    /// - Parameters:
    ///   - url: The location of the photo
    ///   - size: Size of the photo
    @objc public convenience init(withUrl url: URL, size: CGSize) {
        self.init(asset: URLAsset(url, size: size))!
    }
    
    /// Creates a PhotobookAsset using a UIImage
    ///
    /// - Parameters:
    ///   - image: The UIImage to use
    ///   - date: Date for the PhotobookAsset
    @objc public convenience init(withImage image: UIImage, date: Date? = nil) {
        self.init(asset: ImageAsset(image: image, date: date))!
    }
    
    /// Creates a PhotobookAsset using an AssetDataSource
    ///
    /// - Parameters:
    ///   - dataSource: The data source object to use
    ///   - date: Date for the PhotobookAsset
    @objc public convenience init(withDataSource dataSource: AssetDataSource, size: CGSize, date: Date? = nil) {
        self.init(asset: CustomAsset(dataSource: dataSource, size: size, date: date))!
    }

    override public func isEqual(_ object: Any?) -> Bool {
        if let asset = object as? PhotobookAsset {
            if self.phAsset != nil || asset.phAsset != nil {
                return self.identifier == asset.identifier
            }
            return self.identifier == asset.identifier && self.albumIdentifier == asset.albumIdentifier
        }
        return false
    }
}
