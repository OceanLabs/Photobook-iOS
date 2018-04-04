//
//  SelectedAssetsManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class SelectedAssetsManager: NSObject {
    
    static let notificationUserObjectKeyAssets = "assets"
    static let notificationUserObjectKeyIndices = "indices"
    static let notificationNameSelected = Notification.Name("ly.kite.sdk.SelectedAssetsManager.Selected")
    static let notificationNameDeselected = Notification.Name("ly.kite.sdk.SelectedAssetsManager.Deselected")

    private(set) var selectedAssets = [Asset]()
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereUpdated(_:)), name: AssetsNotificationName.albumsWereUpdated, object: nil)
        
        // Listen for the receipt dismissed notification so that we deselect all selected assets
        NotificationCenter.default.addObserver(self, selector: #selector(deselectAllAssetsForAllAlbums), name: ReceiptNotificationName.receiptWillDismiss, object: nil)
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
    
    func orderAssetsByDate() {
        selectedAssets.sort { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
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
    /// - Returns: False if the asset is not able to be selected because of reaching the limit
    func toggleSelected(_ asset:Asset) -> Bool {
        if isSelected(asset) {
            deselect(asset)
            return true
        } else if count < ProductManager.shared.maximumAllowedAssets {
            select(asset)
            return true
        } else {
            return false
        }
    }
    
    func count(for album: Album) -> Int {
            return selectedAssets(for: album).count
    }
    
    var count: Int {
        return selectedAssets.count
    }
    
    func willSelectingAllExceedTotalAllowed(_ album:Album) -> Bool {
        return selectedAssets.count - selectedAssets(for: album).count + album.assets.count > ProductManager.shared.maximumAllowedAssets
    }
    
    
    func selectAllAssets(for album: Album) {
        select(album.assets)
    }
    
    func deselectAllAssets(for album: Album) {
        deselect(album.assets)
    }
    
    @objc func deselectAllAssetsForAllAlbums(){
        deselect(selectedAssets)
    }
    
    @objc func albumsWereUpdated(_ notification: Notification) {
        guard let albumsChanges = notification.object as? [AlbumChange] else { return }
        
        for albumChange in albumsChanges {
            for asset in albumChange.assetsRemoved {
                if isSelected(asset) {
                    deselect(asset)
                }
            }
        }
        
    }
    
}
