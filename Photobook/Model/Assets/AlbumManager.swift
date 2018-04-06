//
//  AlbumManager
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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
