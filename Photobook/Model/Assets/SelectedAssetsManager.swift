//
//  SelectedAssetsManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

struct Constants {
    static let maximumAllowedPhotosForSelectAll = 70
}

class SelectedAssetsManager: NSObject {

    private var selectedAssets = [String:[Asset]]()
    private var photoBookAssets = [Asset]()
    var assets:[Asset] {
        return photoBookAssets
    }
    
    private func selectedAssets(for album: Album) -> [Asset] {
        let assets = selectedAssets[album.identifier]
        if assets == nil{
            selectedAssets[album.identifier] = [Asset]()
        }
        
        return selectedAssets[album.identifier]!
    }
    
    private func select(_ asset:Asset, for album:Album) {
        var selectedAssetsForAlbum = selectedAssets(for: album)
        selectedAssetsForAlbum.append(asset)
        photoBookAssets.append(asset)
        selectedAssets[album.identifier] = selectedAssetsForAlbum
    }
    
    private func deselect(_ asset:Asset, for album:Album) {
        var selectedAssetsForAlbum = selectedAssets(for: album)
        
        if let index = selectedAssetsForAlbum.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }){
            selectedAssetsForAlbum.remove(at: index)
        }
        
        selectedAssets[album.identifier] = selectedAssetsForAlbum
        
        if let sortedIndex = photoBookAssets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }){
            photoBookAssets.remove(at: sortedIndex)
        }
    }
    
    func isSelected(_ asset:Asset, for album:Album) -> Bool {
        let index = selectedAssets(for: album).index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        })
        
        return index != nil
    }
    
    
    /// Select an asset if it's not selected, deselect it if it is
    ///
    /// - Parameters:
    ///   - asset: The asset to toggle
    ///   - album: The album the asset is in
    /// - Returns: False if the asset is not able to be selected because of reaching the limit
    func toggleSelected(_ asset:Asset, for album:Album) -> Bool {
        if isSelected(asset, for: album){
            deselect(asset, for: album)
        }
        else{
            select(asset, for: album)
        }
        
        //TODO: Check if we've reached the limit
        return true
    }
    
    func count(for album:Album? = nil) -> Int {
        if let album = album{
            return selectedAssets(for: album).count
        }
        
        var count = 0
        for selectedAssetsInAlbum in selectedAssets{
            count += selectedAssetsInAlbum.value.count
        }
        
        return count
    }
    
    func willSelectingAllExceedTotalAllowed(for album: Album) -> Bool {
        var count = 0
        for selectedAssetsInAlbum in selectedAssets{
            if selectedAssetsInAlbum.key == album.identifier { continue } //Skip counting selected in album
            count += selectedAssetsInAlbum.value.count
        }
        
        return count + album.assets.count > Constants.maximumAllowedPhotosForSelectAll
    }
    
    
    func selectAllAssets(for album: Album){
        for asset in album.assets{
            if !isSelected(asset, for: album){
                select(asset, for: album)
            }
        }
    }
    
    func deselectAllAssets(for album: Album){
        for asset in album.assets{
            if isSelected(asset, for: album){
                deselect(asset, for: album)
            }
        }
    }
    
    func preparePhotoBookAssets(minimumNumberOfAssets minimum:Int = 0){
        var assets = [Asset]()
        
        for selectedAssetsInAlbum in selectedAssets{
            assets.append(contentsOf: selectedAssetsInAlbum.value)
        }
        
        // TODO: Sort
//        assets.sort(by: {$0.date > $1.date})
        
        // Duplicate the first photo to use as both the cover AND the first page 🙄
        if let first = assets.first{
            assets.insert(first, at: 0)
        }
        
        while assets.count < minimum{
            assets.append(PlaceholderAsset())
        }
        
        photoBookAssets = assets
    }
    
}
