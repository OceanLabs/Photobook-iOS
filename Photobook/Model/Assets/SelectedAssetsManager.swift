//
//  SelectedAssetsManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit


/// Temporary class to hold selected assets. Replace with whatever solution is implemented in PHO-5
class SelectedAssetsManager: NSObject {

    private static var selectedAssets = [String:[Asset]]()
    private static let maximumAllowedPhotosForSelectAll = 70
    
    static func selectedAssets(_ album: Album) -> [Asset]{
        let assets = selectedAssets[album.identifier]
        if assets == nil{
            selectedAssets[album.identifier] = [Asset]()
        }
        
        return selectedAssets[album.identifier]!
    }
    
    static func setSelectedAssets(_ album: Album, newSelectedAssets: [Asset]){
        selectedAssets[album.identifier] = newSelectedAssets
    }
    
    static func willSelectingAllExceedTotalAllowed(in album: Album) -> Bool{
        var count = 0
        for selectedAssetsInAlbum in selectedAssets{
            if selectedAssetsInAlbum.key == album.identifier { continue } //Skip counting selected in album
            count += selectedAssetsInAlbum.value.count
        }
        
        return count + album.assets.count > maximumAllowedPhotosForSelectAll
    }
    
}
