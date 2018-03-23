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
}

enum AssetDataFileExtension: String {
    case jpg
    case png
    case gif
    case unsupported
}

/// Represents a photo used in a photo book
protocol Asset: Codable {
    
    /// Identifier
    var identifier: String! { get set }
    
    /// Album Identifier
    var albumIdentifier: String { get }
    
    /// Size
    var size: CGSize { get }
    
    /// True if the orientation of the image representation of the Asset landscape
    var isLandscape: Bool { get }
    
    /// Date
    var date: Date? { get }
    
    /// URL of full size image to use in the Photobook generation
    var uploadUrl: String? { get set }
    
    /// Request the image that this asset represents.
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline
    ///   - loadThumbnailsFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the image
    func image(size: CGSize, loadThumbnailsFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void)
    
    
    /// Request the data representation of this asset
    ///
    /// - Parameters:
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the data
    func imageData(progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ data: Data?, _ fileExtension: AssetDataFileExtension?, _ error: Error?) -> Void)
}

extension Asset {
    
    /// Request the image that this asset represents. This function calls the protocol method with some default parameters
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline
    ///   - loadThumbnailsFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the image
    func image(size: CGSize, loadThumbnailsFirst: Bool = true, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)? = nil, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void){
        
        image(size: size, loadThumbnailsFirst: loadThumbnailsFirst, progressHandler: progressHandler, completionHandler: completionHandler)
    }
}

func ==(lhs: Asset, rhs: Asset) -> Bool{
    return lhs.identifier == rhs.identifier && lhs.albumIdentifier == rhs.albumIdentifier
}
