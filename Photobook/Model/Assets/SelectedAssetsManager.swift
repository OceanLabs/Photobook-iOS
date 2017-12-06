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
    
    static let notificationUserObjectKeyAsset = "asset"
    static let notificationUserObjectKeyIndex = "index"
    static let notificationNameSelected = Notification.Name("SelectedAssetsManager.Selected")
    static let notificationNameDeselected = Notification.Name("SelectedAssetsManager.Deselected")
    static let notificationNameCleared = Notification.Name("SelectedAssetsManager.Cleared")

    private(set) var selectedAssets = [Asset]()
    
    override init() {
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func areAssetsEqual(_ asset1:Asset, _ asset2:Asset) -> Bool {
        return asset1.identifier == asset2.identifier && asset1.albumIdentifier == asset2.albumIdentifier
    }
    
    private func selectedAssets(for album: Album) -> [Asset] {
        return selectedAssets.filter { (a) -> Bool in
            return a.albumIdentifier == album.identifier
        }
    }
    
    private func select(_ asset:Asset) {
        if selectedAssets.index(where: { (selectedAsset) in
            return areAssetsEqual(selectedAsset, asset)
        }) != nil {
            //already added
            return
        }
        
        selectedAssets.append(asset)
        NotificationCenter.default.post(name: SelectedAssetsManager.notificationNameSelected, object: nil, userInfo: [SelectedAssetsManager.notificationUserObjectKeyAsset:asset, SelectedAssetsManager.notificationUserObjectKeyIndex:selectedAssets.count-1])
    }
    
    func deselect(_ asset:Asset) {
        if let index = selectedAssets.index(where: { (selectedAsset) in
            return areAssetsEqual(selectedAsset, asset)
        }) {
            selectedAssets.remove(at: index)
            NotificationCenter.default.post(name: SelectedAssetsManager.notificationNameDeselected, object: nil, userInfo: [SelectedAssetsManager.notificationUserObjectKeyAsset:asset, SelectedAssetsManager.notificationUserObjectKeyIndex:index])
        }
    }
    
    func isSelected(_ asset:Asset) -> Bool {
        let index = selectedAssets.index(where: { (selectedAsset) in
            return areAssetsEqual(selectedAsset, asset)
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
    
    func willSelectingAllExceedTotalAllowed() -> Bool {
        return selectedAssets.count > Constants.maximumAllowedPhotosForSelectAll
    }
    
    
    func selectAllAssets(for album: Album){
        for asset in album.assets{
            if !isSelected(asset) {
                select(asset)
            }
        }
    }
    
    func deselectAllAssets(for album: Album){
        for asset in album.assets{
            if !isSelected(asset) {
                select(asset)
            }
        }
    }
    
    func deselectAllAssets(){
        selectedAssets = [Asset]()
        NotificationCenter.default.post(name: SelectedAssetsManager.notificationNameCleared, object: nil)
    }
    
}
