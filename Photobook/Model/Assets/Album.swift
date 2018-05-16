//
//  Album.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

/// Collection of Assets
protocol Album {
    
    // Identifier
    var identifier: String { get }

    /// Number of Assets in the album
    var numberOfAssets: Int { get }
    
    /// Localized name
    var localizedName: String? { get }
    
    /// Collection of already loaded Assets
    var assets: [Asset] { get }
    
    /// True if the album has more Assets to load, False otherwise
    var hasMoreAssetsToLoad: Bool { get }
    
    /// Performs the loading of a first batch of Assets
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func loadAssets(completionHandler: ((_ error: Error?) -> Void)?)
    
    /// Performs the loading of the next batch of Assets
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func loadNextBatchOfAssets(completionHandler: ((_ error: Error?) -> Void)?)
    
    /// Retrieves the Asset to be used as cover for the Album
    ///
    /// - Parameter completionHandler: Closure that gets called on completion
    func coverAsset(completionHandler: @escaping (_ asset: Asset?, _ error: Error?) -> Void)
}

struct AlbumChange {
    var album: Album
    var assetsRemoved: [Asset]
    var indexesRemoved: [Int]
    var assetsInserted: [Asset]
}

struct AlbumAddition {
    var album: Album
    var index: Int
}
