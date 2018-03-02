//
//  Album.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol Album {
    
    /// Returns the estimated number of assets of this album, which might be available without calling loadAssets. It might differ from the actual number of assets. Returns NSNotFound if it isn't available.
    var numberOfAssets: Int { get }
    var localizedName: String? { get }
    var identifier: String { get }
    var assets: [Asset] { get }
    var hasMoreAssetsToLoad: Bool { get }
    
    func loadAssets(completionHandler: ((_ error: Error?) -> Void)?)
    func loadNextBatchOfAssets()
    func coverAsset(completionHandler: @escaping (_ asset: Asset?, _ error: Error?) -> Void)
    
}

struct AlbumChange {
    var album: Album
    var assetsRemoved: [Asset]
    var indexesRemoved: [Int]
    var assetsAdded: [Asset]
}

struct AlbumAddition {
    var album: Album
    var index: Int
}
