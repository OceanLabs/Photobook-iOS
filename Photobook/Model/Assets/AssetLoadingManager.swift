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
    ///   - asset: The asset to get the image from.
    ///   - size: The requested image size in points. Depending on the asset type and source this size may just a guideline.
    ///   - loadThumbnailFirst: Whether thumbnails get loaded first before the actual image. Setting this to true will result in the completion handler being executed multiple times.
    ///   - progressHandler: Handler that returns the progress, for example of a download.
    ///   - completionHandler: The completion handler that returns the image.
    func image(for asset: Asset, size: CGSize, loadThumbnailFirst: Bool, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
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
    func imageData(for asset: Asset, progressHandler: ((_ downloaded: Int64, _ total: Int64) -> Void)?, completionHandler: @escaping (_ data: Data?, _ fileExtension: AssetDataFileExtension, _ error: Error?) -> Void) {
        processingQueue.async {
            self.semaphore.wait()
            asset.imageData(progressHandler: progressHandler, completionHandler: { data, fileExtension, error in
                completionHandler(data, fileExtension, error)
                self.semaphore.signal()
            })
        }
    }

}
