//
//  AlbumManager
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

struct AssetsNotificationName {
    static let albumsWereUpdated = Notification.Name("albumsWereUpdatedNotificationName")
}

protocol AlbumManager {
    var albums:[Album] { get }
    
    func loadAlbums(completionHandler: ((_ errorMessage: ActionableErrorMessage?) -> Void)?)
    
    func stopCachingImagesForAllAssets()
    func startCachingImages(for assets: [Asset], targetSize: CGSize)
    func stopCachingImages(for assets: [Asset], targetSize: CGSize)
}
