//
//  AssetPickerCollectionViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AssetPickerCollectionViewController: UICollectionViewController {

    private let marginBetweenImages = CGFloat(1)
    private let numberOfCellsPerRow = CGFloat(4) //CGFloat because it's used in size calculations
    var album: Album! {
        didSet{
            self.title = album.localizedName
            
            if album.assets.count == 0{
                album.loadAssets(completionHandler: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: collectionView!)
        }
    }
    
    @IBAction func unwindToThisView(withUnwindSegue unwindSegue: UIStoryboardSegue) {}

}

extension AssetPickerCollectionViewController {
    //MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetPickerCollectionViewCell", for: indexPath) as? AssetPickerCollectionViewCell else { return UICollectionViewCell() }
        
        let asset = album.assets[indexPath.item]
        cell.assetId = asset.identifier
        
        if SelectedAssetsManager.selectedAssets(album).contains(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }) {
            cell.selectedStatusImageView.image = UIImage(named: "Tick")
        } else {
            cell.selectedStatusImageView.image = UIImage(named: "Tick-empty")
        }
        
        let size = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
        asset.image(size: size, completionHandler: {(image, _) in
            guard cell.assetId == asset.identifier else { return }
            cell.imageView.image = image
        })
        
        return cell
    }
    
}

extension AssetPickerCollectionViewController {
    //MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = album.assets[indexPath.item]
        
        var selectedAssets = SelectedAssetsManager.selectedAssets(album)
        if let index = selectedAssets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }){
            selectedAssets.remove(at: index)
        } else {
            selectedAssets.append(asset)
        }
        
        SelectedAssetsManager.setSelectedAssets(album, newSelectedAssets: selectedAssets)
        collectionView.reloadItems(at: [indexPath])
    }
    
}

extension AssetPickerCollectionViewController: UICollectionViewDelegateFlowLayout{
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var usableSpace = collectionView.frame.size.width - marginBetweenImages;
        usableSpace -= (numberOfCellsPerRow - 1.0) * marginBetweenImages
        let cellWidth = usableSpace / numberOfCellsPerRow
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

extension AssetPickerCollectionViewController: UIViewControllerPreviewingDelegate{
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? AssetPickerCollectionViewCell,
            let thumbnailImage = cell.imageView.image,
            let fullScreenImageViewController = storyboard?.instantiateViewController(withIdentifier: "FullScreenImageViewController") as? FullScreenImageViewController
            else { return nil }
        
        previewingContext.sourceRect = cell.convert(cell.contentView.frame, to: collectionView)
        
        fullScreenImageViewController.asset = album.assets[indexPath.item]
        fullScreenImageViewController.album = album
        fullScreenImageViewController.sourceView = cell.imageView
        fullScreenImageViewController.delegate = self
        fullScreenImageViewController.providesPresentationContextTransitionStyle = true
        fullScreenImageViewController.definesPresentationContext = true
        fullScreenImageViewController.modalPresentationStyle = .overCurrentContext
        
        // Use the cell's image to calculate the image's aspect ratio
        fullScreenImageViewController.preferredContentSize = CGSize(width: view.frame.size.width, height: view.frame.size.width * (thumbnailImage.size.height / thumbnailImage.size.width) - 1) // -1 because otherwise a black line can be seen above the image
        
        return fullScreenImageViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let fullScreenImageViewController = viewControllerToCommit as? FullScreenImageViewController else { return }
        fullScreenImageViewController.prepareForPop()
        
        present(viewControllerToCommit, animated: true, completion: nil)
    }
    
}

extension AssetPickerCollectionViewController: FullScreenImageViewControllerDelegate{
    func fullScreenImageViewControllerDidUpdateAsset(asset: Asset) {
        guard let index = album.assets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }),
            index != NSNotFound
            else { return }
        
        collectionView?.reloadItems(at: [IndexPath(item: index, section: 0)])
    }
}
