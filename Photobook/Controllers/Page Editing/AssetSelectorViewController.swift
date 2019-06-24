//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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

    private lazy var timesUsed: [String: Int] = {
        var temp = [String: Int]()
        
        for layout in product.productLayouts {
            guard let asset = layout.asset else { continue }
            temp[asset.identifier] = temp[asset.identifier] != nil ? temp[asset.identifier]! + 1 : 1
        }
        return temp
    }()
    private var selectedAssetIndex = -1
    
    weak var photobookDelegate: PhotobookDelegate? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    weak var delegate: AssetSelectorDelegate?
    weak var assetsDelegate: PhotobookAssetsDelegate?
    
    var assets: [Asset]! {
        return assetsDelegate!.assets!
    }
    
    var selectedAsset: Asset? {
        didSet {
            guard selectedAsset != nil else {
                if let previousAsset = oldValue, timesUsed[previousAsset.identifier] != nil {
                    if assets.firstIndex(where: { $0.identifier == previousAsset.identifier }) == nil {
                        timesUsed.removeValue(forKey: previousAsset.identifier)
                    } else {
                        timesUsed[previousAsset.identifier] = timesUsed[previousAsset.identifier]! - 1
                    }
                }
                selectedAssetIndex = -1
                collectionView.reloadData()
                collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
                return
            }
            selectedAssetIndex = assets.firstIndex { $0.identifier == selectedAsset!.identifier } ?? -1
            if collectionView.numberOfItems(inSection: 0) > selectedAssetIndex && selectedAssetIndex >= 0 {
                collectionView.scrollToItem(at: IndexPath(item: selectedAssetIndex, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
    }
    var browseNavigationController: UINavigationController!
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    private lazy var shouldShowAddMoreButton = photobookDelegate?.assetPickerViewController != nil
    
    func reselectAsset(_ asset: Asset) {
        selectedAsset = asset
        timesUsed[selectedAsset!.identifier] = timesUsed[selectedAsset!.identifier]! + 1
        collectionView.reloadData()
    }
}

extension AssetSelectorViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add one for the "add more" thumbnail if an Asset picker was configured
        var count = assets.count
        if shouldShowAddMoreButton { count += 1 }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // "Add more" thumbnail
        if indexPath.item == 0 && shouldShowAddMoreButton {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAddMoreCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAddMoreCollectionViewCell
        }
        
        let assetIndex = indexPath.item - (shouldShowAddMoreButton ? 1 : 0)

        let asset = assets[assetIndex]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetSelectorAssetCollectionViewCell.reuseIdentifier, for: indexPath) as! AssetSelectorAssetCollectionViewCell
        let selected = selectedAssetIndex == assetIndex
        cell.isBorderVisible = selected
        
        let timesUsed = (self.timesUsed[asset.identifier] ?? 0)
        cell.timesUsed = timesUsed
        
        cell.assetIdentifier = asset.identifier
        let itemSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        
        cell.assetImageView.setImage(from: asset, size: itemSize, validCellCheck: {
            return cell.assetIdentifier == asset.identifier
        })
        
        cell.isAccessibilityElement = true
        
        let imageName = timesUsed == 1 ? NSLocalizedString("Accessibility/Editing/imageUsed1Times", value: "Image used 1 time", comment: "Accessibility label for an image used 1 time") : NSLocalizedString("Accessibility/Editing/imageUsedNTimes", value: "Image used \(timesUsed) times", comment: "Accessibility label for an image used multiple times")
        cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + imageName
        
        return cell
    }
}

extension AssetSelectorViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 && shouldShowAddMoreButton {
            if let assetPickerViewController = photobookDelegate!.assetPickerViewController?() {
                assetPickerViewController.addingDelegate = self
                present(assetPickerViewController, animated: photobookDelegate!.shouldAnimateAssetPicker ?? true, completion: nil)
                return
            }
        }
        
        let assetIndex = indexPath.item - (shouldShowAddMoreButton ? 1 : 0)
        guard selectedAssetIndex != assetIndex else { return }

        if let selectedAsset = selectedAsset {
            timesUsed[selectedAsset.identifier] = timesUsed[selectedAsset.identifier]! - 1
            
            if let currentSelectedCell = collectionView.cellForItem(at: IndexPath(item: selectedAssetIndex + (shouldShowAddMoreButton ? 1 : 0), section: 0)) as? AssetSelectorAssetCollectionViewCell {
                currentSelectedCell.timesUsed = timesUsed[selectedAsset.identifier]!
                currentSelectedCell.isBorderVisible = false
            }
        }
        
        selectedAsset = assets[assetIndex]
        timesUsed[selectedAsset!.identifier] = (timesUsed[selectedAsset!.identifier] ?? 0) + 1
        if let newSelectedCell = collectionView.cellForItem(at: indexPath) as? AssetSelectorAssetCollectionViewCell {
            newSelectedCell.timesUsed = timesUsed[selectedAsset!.identifier]!
            newSelectedCell.isBorderVisible = true
        }

        delegate?.didSelect(asset: assets[assetIndex])
    }
}

extension AssetSelectorViewController: PhotobookAssetAddingDelegate {
    
    func didFinishAdding(_ photobookAssets: [PhotobookAsset]?) {
                
        guard let assets = PhotobookAsset.assets(from: photobookAssets), !assets.isEmpty else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        // Add assets that are not already in the list
        let newAssets = assets.filter { asset in !self.assets.contains { $0 == asset } }
        for asset in newAssets {
            assetsDelegate!.assets!.insert(asset, at: 0)
        }

        selectedAssetIndex = self.assets.firstIndex { $0.identifier == selectedAsset?.identifier } ?? -1
        collectionView.reloadData()
        self.dismiss(animated: photobookDelegate?.shouldAnimateAssetPicker ?? true, completion: nil)
    }
}
