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

enum AssetDataFileExtension: String {
    case jpg
    case png
    case gif
    case unsupported
}

protocol Asset: Codable {
    var identifier: String! { get set }
    var size: CGSize { get }
    var isLandscape: Bool { get }
    var uploadUrl: String? { get set }
    var assetType: String { get }
    var date: Date? { get }
    
    var albumIdentifier: String { get }
    
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
    func imageData(progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ data: Data?, _ fileExtension: AssetDataFileExtension?, _ error: Error?) -> Void)
}

extension Asset {
    
    /// Request the image that this asset represents. This function calls the protocol method with some default parameters
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline
    ///   - loadThumbnailFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the image
    func image(size: CGSize, loadThumbnailFirst: Bool = true, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)? = nil, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void){
        
        image(size: size, loadThumbnailFirst: loadThumbnailFirst, progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /// Removes slashes because it'd result in an invalid path
    var fileIdentifier: String {
        get {
            return identifier.replacingOccurrences(of: "/", with: "")
        }
    }
}

func ==(lhs: Asset, rhs: Asset) -> Bool{
    return lhs.identifier == rhs.identifier && lhs.albumIdentifier == rhs.albumIdentifier
}
