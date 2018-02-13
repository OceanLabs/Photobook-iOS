//
//  Asset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

let assetMaximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

enum AssetLoadingException: Error {
    case notFound
}

protocol Asset: Codable {
    var identifier: String! { get set }
    var size: CGSize { get }
    var isLandscape: Bool { get }
    var uploadUrl: String? { get set }
    var assetType: String { get }
    var date: Date? { get }
    
    var albumIdentifier: String { get }
    
    /// Request the original, unedited image that this asset represents. Avoid using this method directly, instead use image(size:applyEdits:contentMode:cacheResult:progressHandler:completionHandler:)
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline
    ///   - loadThumbnailsFirst: whether loading mode will be opportunistic. Setting this to true might result in loading a thumbnail before the actual image, which will result in the completion handler being executed multiple times
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the image
    func uneditedImage(size: CGSize, loadThumbnailsFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void)
}

extension Asset {
    
    /// Request the image that this asset represents. This method will do all of the processing in a serial background thread.
    ///
    /// - Parameters:
    ///   - size: The requested image size in points. Depensding on the asset type and source this size may just a guideline
    ///   - applyEdits: Option to apply the edits that the user has made
    ///   - loadThumbnail: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times
    ///   - progressHandler: Handler that returns the progress, for a example of a download
    ///   - completionHandler: The completion handler that returns the image
    func image(size: CGSize, applyEdits: Bool = true, loadThumbnailsFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)? = nil, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void){
        
        uneditedImage(size: size, loadThumbnailsFirst: loadThumbnailsFirst, progressHandler: progressHandler, completionHandler: {(image: UIImage?, error: Error?) -> Void in
            guard error == nil else{
                completionHandler(nil, error)
                return
            }
            guard let image = image else{
                completionHandler(nil, NSError()) //TODO: better error reporting
                return
            }
            
            //TODO: apply edits here if needed
            
            DispatchQueue.main.async {
                completionHandler(image, nil)
            }
        })
    }
}

func ==(lhs: Asset, rhs: Asset) -> Bool{
    return lhs.identifier == rhs.identifier && lhs.albumIdentifier == rhs.albumIdentifier
}
