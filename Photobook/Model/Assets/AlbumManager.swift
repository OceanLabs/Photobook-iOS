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

struct AssetsNotificationName {
    static let albumsWereUpdated = Notification.Name("ly.kite.sdk.albumsWereUpdatedNotificationName")
    static let albumsWereAdded = Notification.Name("ly.kite.sdk.albumsWereAddedNotificationName")
}

/// Manager for a source with multiple albums
protocol AlbumManager {
    
    /// The title for the Album collection or source. E.g. Facebook Albums
    var title: String { get }
    
    /// The collection of loaded Albums
    var albums: [Album] { get }
    
    /// Flag indicating whether there are more Albums available
    var hasMoreAlbumsToLoad: Bool { get }
    
    /// Performs the loading of a first batch of Albums
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func loadAlbums(completionHandler: ((_ errorMessage: Error?) -> Void)?)
    
    /// Performs the loading of the next batch of Albums
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func loadNextBatchOfAlbums(completionHandler: ((_ errorMessage: Error?) -> Void)?)
    
    /// Caches images for the provided assets and size
    ///
    /// - Parameters:
    ///   - assets: Assets for which to cache images
    ///   - targetSize: The desired size for the images
    func startCachingImages(for assets: [Asset], targetSize: CGSize)

    /// Stops the process of caching images for the provided assets and size
    ///
    /// - Parameters:
    ///   - assets: Assets for which to cache images
    ///   - targetSize: The desired size for the images
    func stopCachingImages(for assets: [Asset], targetSize: CGSize)
    
    /// Stops the process of caching images for all assets in 'assets'
    func stopCachingImagesForAllAssets()
}

// MARK: - Default implementation for optional methods
extension AlbumManager {
    func startCachingImages(for assets: [Asset], targetSize: CGSize) {}
    func stopCachingImages(for assets: [Asset], targetSize: CGSize) {}
    func stopCachingImagesForAllAssets() {}
}
