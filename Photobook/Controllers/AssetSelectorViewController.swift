//
//  AssetSelectorViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 04/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos

/// Protocol a delegate has to conform to to be notified about asset selection
protocol AssetSelectorDelegate: class {
    func didSelect(asset: Asset)
}

class AssetSelectorViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var selectedAssetsManager: SelectedAssetsManager! {
        didSet {
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: SelectedAssetsManager.notificationNameSelected, object: oldValue)
                NotificationCenter.default.removeObserver(self, name: SelectedAssetsManager.notificationNameDeselected, object: oldValue)
            }
            NotificationCenter.default.addObserver(self, selector: #selector(changedCollectedAssets), name: SelectedAssetsManager.notificationNameSelected, object: selectedAssetsManager)
            NotificationCenter.default.addObserver(self, selector: #selector(changedCollectedAssets), name: SelectedAssetsManager.notificationNameDeselected, object: selectedAssetsManager)
        }
    }
    
//    private var assets: [Asset] {
//        get {
//            if let manager = selectedAssetsManager {
//                return manager.selectedAssets
//            }
//            return [Asset]()
//        }
//    }
    private lazy var assets: [Asset] = {
        let phAssets = PHAsset.fetchAssets(with: PHFetchOptions())
        
        var assets = [PhotosAsset]()
        phAssets.enumerateObjects { (asset, _, _) in
            let photoAsset = PhotosAsset(asset, collection: PHAssetCollection())
            assets.append(photoAsset)
        }
        return assets
    }()
    
    private var selectedAssetIndex = -1
    
    weak var delegate: AssetSelectorDelegate?
    
    var selectedAsset: Asset? {
        didSet {
            guard selectedAsset != nil else {
                selectedAssetIndex = -1
                return
            }
            selectedAssetIndex = assets.index { $0.identifier == selectedAsset!.identifier } ?? -1
            self.collectionView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func changedCollectedAssets() {
        
    }
}

extension AssetSelectorViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one for the "add more" thumbnail
        return assets.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // "Add more" thumbnail
        if indexPath.row == assets.count {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAddMoreCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAddMoreCollectionViewCell
        }

        let asset = assets[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAssetCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAssetCollectionViewCell
        cell.isAssetSelected = (selectedAssetIndex == indexPath.row)
        cell.timesUsed = selectedAssetIndex == indexPath.row ? 1 : 0
        cell.assetIdentifier = asset.identifier
        let itemSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        
        asset.image(size: itemSize, completionHandler: { (image, error) in
            guard cell.assetIdentifier == asset.identifier, error == nil else { return }
            cell.assetImage = image
        })
        
        return cell
    }
}

extension AssetSelectorViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == assets.count {
            // TODO: Present asset picker screen
            return
        }
        
        guard selectedAssetIndex != indexPath.row else { return }
        
        selectedAssetIndex = indexPath.row
        collectionView.reloadData()
        
        delegate?.didSelect(asset: assets[indexPath.row])
    }
}
