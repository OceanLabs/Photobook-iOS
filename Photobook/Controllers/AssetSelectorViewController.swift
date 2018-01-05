//
//  AssetSelectorViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 04/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Photos

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

class AssetSelectorAssetCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(AssetSelectorAssetCollectionViewCell.self).components(separatedBy: ".").last!
    
    static let cornerRadius: CGFloat = 8.0
    static let borderWidth: CGFloat = 3.0
    static let borderInset: CGFloat = 1.0
    // TEMP: Refactor common colours out into utility class
    static let borderColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor
    
    @IBOutlet private weak var assetImageView: UIImageView! {
        didSet {
            let rect = assetImageView.bounds
            let path = UIBezierPath(roundedRect: rect, cornerRadius: AssetSelectorAssetCollectionViewCell.cornerRadius).cgPath
            
            let maskLayer = CAShapeLayer()
            maskLayer.fillColor = UIColor.white.cgColor
            maskLayer.path = path
            maskLayer.frame = assetImageView.bounds
            
            assetImageView.layer.mask = maskLayer
        }
    }
    @IBOutlet private weak var badgeBackgroundView: UIView!
    @IBOutlet private weak var badgeLabel: UILabel!
    
    private var borderLayer: CAShapeLayer!
    
    var assetIdentifier: String!
    var assetImage: UIImage? {
        didSet {
            self.assetImageView.image = assetImage
        }
    }
    
    var isAssetSelected = false {
        willSet {
            guard isAssetSelected != newValue else { return }
            if newValue {
                layer.addSublayer(borderLayer)
            } else {
                borderLayer.removeFromSuperlayer()
            }
        }
    }
    var timesUsed = 0 {
        didSet {
            badgeBackgroundView.alpha = timesUsed > 0 ? 1.0 : 0.0
            badgeLabel.alpha = timesUsed > 0 ? 1.0 : 0.0
            badgeLabel.text = String(timesUsed)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        let inset = AssetSelectorAssetCollectionViewCell.borderInset
        let rect = CGRect(x: -inset, y: -inset, width: self.bounds.width + 2.0 * inset, height: self.bounds.height + 2.0 * inset)
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: AssetSelectorAssetCollectionViewCell.cornerRadius).cgPath
        borderLayer = CAShapeLayer()
        borderLayer.fillColor = nil
        borderLayer.path = borderPath
        borderLayer.frame = self.bounds
        borderLayer.strokeColor = AssetSelectorAssetCollectionViewCell.borderColor
        borderLayer.lineWidth = AssetSelectorAssetCollectionViewCell.borderWidth
    }
}

class AssetSelectorAddMoreCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(AssetSelectorAddMoreCollectionViewCell.self).components(separatedBy: ".").last!

    static let cornerRadius: CGFloat = 8.0

    @IBOutlet weak var backgroundColorView: UIView! {
        didSet {
            let rect = backgroundColorView.bounds
            let path = UIBezierPath(roundedRect: rect, cornerRadius: AssetSelectorAddMoreCollectionViewCell.cornerRadius).cgPath
            
            let maskLayer = CAShapeLayer()
            maskLayer.fillColor = UIColor.white.cgColor
            maskLayer.path = path
            maskLayer.frame = backgroundColorView.bounds
            
            backgroundColorView.layer.mask = maskLayer
        }
    }
}
