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
    
    static let assetSelectorAddedAssets = Notification.Name("assetSelectorAddedAssets")
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var addMoreSelectedAssetsManager = SelectedAssetsManager()
    var assets = [Asset]()

    private lazy var timesUsed: [String: Int] = {
        var temp = [String: Int]()
        
        for layout in ProductManager.shared.productLayouts {
            guard let asset = layout.asset else { continue }
            temp[asset.identifier] = temp[asset.identifier] != nil ? temp[asset.identifier]! + 1 : 1
        }
        return temp
    }()
    private var selectedAssetIndex = -1
    
    var album: Album? {
        didSet {
            if album != nil { collectionView.reloadData() }
        }
    }
    var albumManager: AlbumManager? {
        didSet {
            if albumManager != nil { collectionView.reloadData() }
        }
    }
    var assetPickerViewController: PhotobookAssetPicker? {
        didSet {
            if assetPickerViewController != nil { collectionView.reloadData() }
        }
    }
    
    weak var delegate: AssetSelectorDelegate?
    
    var selectedAsset: Asset? {
        didSet {
            guard selectedAsset != nil else {
                if let previousAsset = oldValue, timesUsed[previousAsset.identifier] != nil {
                    if assets.index(where: { $0.identifier == previousAsset.identifier }) == nil {
                        timesUsed.removeValue(forKey: previousAsset.identifier)
                    } else {
                        timesUsed[previousAsset.identifier] = timesUsed[previousAsset.identifier]! - 1
                    }
                }
                selectedAssetIndex = -1
                collectionView.reloadData()
                collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
                return
            }
            selectedAssetIndex = assets.index { $0.identifier == selectedAsset!.identifier } ?? -1
            if collectionView.numberOfItems(inSection: 0) > selectedAssetIndex && selectedAssetIndex >= 0 {
                collectionView.scrollToItem(at: IndexPath(row: selectedAssetIndex, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
    }
    var browseNavigationController: UINavigationController!
    
    func reselectAsset(_ asset: Asset) {
        selectedAsset = asset
        timesUsed[selectedAsset!.identifier] = timesUsed[selectedAsset!.identifier]! + 1
    }
}

extension AssetSelectorViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one for the "add more" thumbnail if an Asset picker was configured
        var count = assets.count
        if album != nil || albumManager != nil || assetPickerViewController != nil { count += 1 }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // "Add more" thumbnail
        if indexPath.row == assets.count {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAddMoreCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAddMoreCollectionViewCell
        }

        let asset = assets[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAssetCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAssetCollectionViewCell
        cell.isBorderVisible = selectedAssetIndex == indexPath.row
        cell.timesUsed = (timesUsed[asset.identifier] ?? 0)
        
        cell.assetIdentifier = asset.identifier
        let itemSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        
        cell.assetImageView.setImage(from: asset, size: itemSize, validCellCheck: {
            return cell.assetIdentifier == asset.identifier
        })
        
        return cell
    }
}

extension AssetSelectorViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == assets.count {
            if let assetPickerViewController = assetPickerViewController {
                assetPickerViewController.addingDelegate = self
                present(assetPickerViewController as! UIViewController, animated: true, completion: nil)
                return
            }
            
            let modalAlbumsCollectionViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "ModalAlbumsCollectionViewController") as! ModalAlbumsCollectionViewController
            modalAlbumsCollectionViewController.album = album
            modalAlbumsCollectionViewController.albumManager = albumManager
            modalAlbumsCollectionViewController.addingDelegate = self
            
            present(modalAlbumsCollectionViewController, animated: false, completion: nil)
            return
        }
        
        guard selectedAssetIndex != indexPath.row else { return }

        if let selectedAsset = selectedAsset {
            timesUsed[selectedAsset.identifier] = timesUsed[selectedAsset.identifier]! - 1
            
            if let currentSelectedCell = collectionView.cellForItem(at: IndexPath(row: selectedAssetIndex, section: 0)) as? AssetSelectorAssetCollectionViewCell {
                currentSelectedCell.timesUsed = timesUsed[selectedAsset.identifier]!
                currentSelectedCell.isBorderVisible = false
            }
        }
        
        selectedAsset = assets[indexPath.row]
        timesUsed[selectedAsset!.identifier] = (timesUsed[selectedAsset!.identifier] ?? 0) + 1
        if let newSelectedCell = collectionView.cellForItem(at: indexPath) as? AssetSelectorAssetCollectionViewCell {
            newSelectedCell.timesUsed = timesUsed[selectedAsset!.identifier]!
            newSelectedCell.isBorderVisible = true
        }

        delegate?.didSelect(asset: assets[indexPath.row])
    }
}

extension AssetSelectorViewController: AssetCollectorAddingDelegate {
    
    func didFinishAdding(_ assets: [PhotobookAsset]?) {
        guard let assets = assets as? [Asset], !assets.isEmpty else {
            self.dismiss(animated: false, completion: nil)
            return
        }
        
        // Add assets that are not already in the list
        let newAssets = assets.filter { asset in !self.assets.contains { $0 == asset } }
        self.assets.append(contentsOf: newAssets)

        collectionView.reloadData()
        collectionView.scrollToItem(at: IndexPath(row: self.assets.count, section: 0), at: .centeredHorizontally, animated: true)
        self.dismiss(animated: false, completion: nil)
    }    
}
