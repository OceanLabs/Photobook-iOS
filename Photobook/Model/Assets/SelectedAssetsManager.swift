//
//  SelectedAssetsManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

struct Constants {
    static let maximumAllowedPhotosForSelectAll = 70
}

class SelectedAssetsManager: NSObject {
    
    static let notificationUserObjectKeyAssets = "assets"
    static let notificationUserObjectKeyIndices = "indices"
    static let notificationNameSelected = Notification.Name("SelectedAssetsManager.Selected")
    static let notificationNameDeselected = Notification.Name("SelectedAssetsManager.Deselected")

    private(set) var selectedAssets = [Asset]()
    
    override init() {
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func selectedAssets(for album: Album) -> [Asset] {
        return selectedAssets.filter { (a) -> Bool in
            return a.albumIdentifier == album.identifier
        }
    }
    
    func select(_ asset:Asset) {
        select([asset])
    }
    
    func select(_ assets:[Asset]) {
        var addedAssets = [Asset]()
        var addedIndices = [Int]()
        for asset in assets {
            if selectedAssets.index(where: { (selectedAsset) in
                return selectedAsset == asset
            }) != nil {
                //already added
                continue
            }
            
            selectedAssets.append(asset)
            addedAssets.append(asset)
            addedIndices.append(selectedAssets.count-1)
        }

        NotificationCenter.default.post(name: SelectedAssetsManager.notificationNameSelected, object: self, userInfo: [SelectedAssetsManager.notificationUserObjectKeyAssets:addedAssets, SelectedAssetsManager.notificationUserObjectKeyIndices:addedIndices])
    }
    
    func deselect(_ asset:Asset) {
        deselect([asset])
    }
    
    func deselect(_ assets:[Asset]) {
        var removedAssets = [Asset]()
        var removedIndices = [Int]()
        for asset in assets {
            if let index = selectedAssets.index(where: { (selectedAsset) in
                return selectedAsset == asset
            }) {
                removedAssets.append(asset)
                removedIndices.append(index)
            }
        }
        for a in removedAssets {
            if let index = selectedAssets.index(where: { (asset) in
                return a == asset
            }) {
                selectedAssets.remove(at: index)
            }
        }
        
        NotificationCenter.default.post(name: SelectedAssetsManager.notificationNameDeselected, object: self, userInfo: [SelectedAssetsManager.notificationUserObjectKeyAssets:removedAssets, SelectedAssetsManager.notificationUserObjectKeyIndices:removedIndices])
    }
    
    func isSelected(_ asset:Asset) -> Bool {
        let index = selectedAssets.index(where: { (selectedAsset) in
            return selectedAsset == asset
        })
        
        return index != nil
    }
    
    
    /// Select an asset if it's not selected, deselect it if it is
    ///
    /// - Parameters:
    ///   - asset: The asset to toggle
    ///   - album: The album the asset is in
    /// - Returns: False if the asset is not able to be selected because of reaching the limit
    func toggleSelected(_ asset:Asset) -> Bool {
        if isSelected(asset){
            deselect(asset)
        }
        else {
            select(asset)
        }
        
        //TODO: Check if we've reached the limit
        return true
    }
    
    func count(for album:Album) -> Int {
        return selectedAssets(for: album).count
    }
    
    func willSelectingAllExceedTotalAllowed(_ album:Album) -> Bool {
        return selectedAssets.count - selectedAssets(for: album).count + album.assets.count > Constants.maximumAllowedPhotosForSelectAll
    }
    
    
    func selectAllAssets(for album: Album){
        select(album.assets)
    }
    
    func deselectAllAssets(for album: Album){
        deselect(album.assets)
    }
    
    func deselectAllAssets(){
        deselect(selectedAssets)
    }
    
}
