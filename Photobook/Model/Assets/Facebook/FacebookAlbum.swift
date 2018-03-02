//
//  FacebookAlbum.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class FacebookAlbum: Album {
    
    init(identifier: String, localizedName: String, numberOfAssets: Int, coverPhotoUrl: URL) {
        self.identifier = identifier
        self.localizedName = localizedName
        self.numberOfAssets = numberOfAssets
        self.coverPhotoUrl = coverPhotoUrl
    }
    
    var numberOfAssets: Int
    
    var localizedName: String?
    
    var identifier: String
    
    var assets = [Asset]()
    
    var requiresExclusivePicking: Bool = false
    
    var hasMoreAssetsToLoad: Bool {
        return false // TODO: fix
    }
    
    var coverPhotoUrl: URL
    
    func loadAssets(completionHandler: ((ActionableErrorMessage?) -> Void)?) {
        
    }
    
    func loadNextBatchOfAssets() {
        
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        completionHandler(URLAsset(thumbnailUrl: coverPhotoUrl, standardResolutionUrl: coverPhotoUrl, albumIdentifier: identifier, size: .zero, identifier: coverPhotoUrl.absoluteString), nil)
    }
    

}
