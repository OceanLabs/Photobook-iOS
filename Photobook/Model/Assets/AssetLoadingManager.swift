//
//  AssetLoadingManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class AssetLoadingManager {
    
    private struct Constants {
        static let maxConcurrentProcessingAssets = ProcessInfo.processInfo.activeProcessorCount
    }
    
    static var shared = AssetLoadingManager()
    let processingQueue = DispatchQueue(label: "AssetLoadingManagerProcessingQueue", qos: .default) // Serial queue
    let semaphore = DispatchSemaphore(value: Constants.maxConcurrentProcessingAssets)
    
    /// Request the image that this asset represents.
    ///
    /// - Parameters:
    ///   - asset: The Asset to get the image from.
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline.
    ///   - loadThumbnailFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times.
    ///   - progressHandler: Handler that returns the progress, for example of a download.
    ///   - completionHandler: The completion handler that returns the image.
    func image(for asset:Asset, size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        processingQueue.async {
            self.semaphore.wait()
            asset.image(size: size, loadThumbnailFirst: loadThumbnailFirst, progressHandler: progressHandler, completionHandler: { image, error in
                completionHandler(image, error)
                self.semaphore.signal()
            })
        }
    }
    
    /// Request the data representation of this asset.
    ///
    /// - Parameters:
    ///   - asset: The Asset to get the image data from.
    ///   - progressHandler: Handler that returns the progress, for example of a download.
    ///   - completionHandler: The completion handler that returns the data.
    func imageData(for asset:Asset, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ data: Data?, _ fileExtension: AssetDataFileExtension, _ error: Error?) -> Void) {
        processingQueue.async {
            self.semaphore.wait()
            asset.imageData(progressHandler: progressHandler, completionHandler: { data, fileExtension, error in
                completionHandler(data, fileExtension, error)
                self.semaphore.signal()
            })
        }
    }

}
