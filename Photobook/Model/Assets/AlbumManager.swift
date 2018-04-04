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

protocol AlbumManager {
    var albums:[Album] { get }
    var title: String { get }
    
    func loadAlbums(completionHandler: ((_ errorMessage: Error?) -> Void)?)
    var hasMoreAlbumsToLoad: Bool { get }
    func loadNextBatchOfAlbums(completionHandler: ((_ errorMessage: Error?) -> Void)?)
    
    func stopCachingImagesForAllAssets()
    func startCachingImages(for assets: [Asset], targetSize: CGSize)
    func stopCachingImages(for assets: [Asset], targetSize: CGSize)
}

struct SelectedAssetsSource {
    var album: Album?
    var albumManager: AlbumManager?
}
