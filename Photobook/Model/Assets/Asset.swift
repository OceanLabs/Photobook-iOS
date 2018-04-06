//
//  Asset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

enum AssetLoadingException: Error {
    case notFound
    case unsupported
}

@objc public enum AssetDataFileExtension: Int {
    case unsupported
    case jpg
    case png
    case gif
}

@objc public protocol PhotobookAsset {}

/// Represents a photo used in a photo book
@objc protocol Asset: PhotobookAsset {
    
    /// Identifier
    var identifier: String! { get set }
    
    /// Album Identifier
    var albumIdentifier: String? { get }
    
    /// Size
    var size: CGSize { get }
    
    /// Date
    var date: Date? { get }
    
    /// URL of full size image to use in the Photobook generation
    var uploadUrl: String? { get set }
    
    /// Request the image that this asset represents.
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline
    ///   - loadThumbnailFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the image
    func image(size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void)
    
    /// Request the data representation of this asset
    ///
    /// - Parameters:
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the data
    func imageData(progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ data: Data?, _ fileExtension: AssetDataFileExtension, _ error: Error?) -> Void)
}

extension Asset {
        
    /// Identifier without forward slashes that can be used as a filename when saving the asset to disk
    var fileIdentifier: String {
        get {
            return identifier.replacingOccurrences(of: "/", with: "")
        }
    }
    
    /// True if the orientation of the image representation of the Asset landscape
    var isLandscape: Bool {
        return size.width > size.height
    }
}

func ==(lhs: Asset, rhs: Asset) -> Bool{
    return lhs.identifier == rhs.identifier && lhs.albumIdentifier == rhs.albumIdentifier
}
