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

enum AssetLoadingException: Error {
    case notFound
    case unsupported(details: String)
}

@objc public enum AssetDataFileExtension: Int {
    case unsupported
    case jpg
    case png
    case gif
}

extension AssetDataFileExtension {
    
    init(string: String) {
        switch string.lowercased() {
        case "jpeg", "jpg": self = .jpg
        case "png": self = .png
        case "gif": self = .gif
        default: self = .unsupported
        }
    }
    
    func string() -> String {
        switch self {
        case .jpg: return "jpg"
        case .png: return "png"
        case .gif: return "gif"
        case .unsupported: return "unsupported"
        }
    }
}

/// Represents a photo used in a photo book.
protocol Asset: Codable {
    
    /// Identifier
    var identifier: String! { get set }
    
    /// Album Identifier
    var albumIdentifier: String? { get }
    
    /// Size
    var size: CGSize { get }
    
    /// Date
    var date: Date? { get }
    
    /// URL of full size image to use in the Photobook generation.
    var uploadUrl: String? { get set }
    
    /// Request the image that this asset represents.
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline.
    ///   - loadThumbnailFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times.
    ///   - progressHandler: Handler that returns the progress, for example of a download.
    ///   - completionHandler: The completion handler that returns the image.
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void)
    
    /// Request the data representation of this asset
    ///
    /// - Parameters:
    ///   - progressHandler: Handler that returns the progress, for example of a download.
    ///   - completionHandler: The completion handler that returns the data.
    func imageData(progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ data: Data?, _ fileExtension: AssetDataFileExtension, _ error: Error?) -> Void)
}

extension Asset {
        
    /// Identifier without forward slashes that can be used as a filename when saving the asset to disk.
    var fileIdentifier: String {
        get {
            return identifier.replacingOccurrences(of: "/", with: "")
        }
    }
    
    /// True if the orientation of the image representation of the Asset landscape.
    var isLandscape: Bool {
        return size.width > size.height
    }
    
    func data() throws -> Data {
        var data: Data
        if let asset = self as? PhotosAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = self as? URLAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = self as? ImageAsset {
            data = try PropertyListEncoder().encode(asset)
        } else if let asset = self as? PhotosAssetMock {
            data = try PropertyListEncoder().encode(asset)
        } else {
            throw AssetLoadingException.unsupported(details: "Asset: Could not convert to data")
        }
        return data
    }
    
    static func asset(from data: Data) throws -> Asset {
        if let asset = try? PropertyListDecoder().decode(URLAsset.self, from: data) {
            return asset
        } else if let asset = try? PropertyListDecoder().decode(ImageAsset.self, from: data) {
            return asset
        } else if let asset = try? PropertyListDecoder().decode(PhotosAsset.self, from: data) { // Keep the PhotosAsset case last because otherwise it triggers NSPhotoLibraryUsageDescription crash if not present, which might not be needed
            return asset
        } else if let asset = try? PropertyListDecoder().decode(PhotosAssetMock.self, from: data) {
            return asset
        } else {
            throw AssetLoadingException.unsupported(details: "From(data:): Decoding of asset failed")
        }
    }
}

func ==(lhs: Asset, rhs: Asset) -> Bool{
    return lhs.identifier == rhs.identifier && lhs.albumIdentifier == rhs.albumIdentifier
}
