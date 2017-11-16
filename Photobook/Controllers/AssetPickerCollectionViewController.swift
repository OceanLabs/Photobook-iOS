//
//  AssetPickerCollectionViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AssetPickerCollectionViewController: UICollectionViewController {

    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private let marginBetweenImages: CGFloat = 1
    private let numberOfCellsPerRow: CGFloat = 4 //CGFloat because it's used in size calculations
    var selectedAssetsManager: SelectedAssetsManager!
    
    var album: Album! {
        didSet{
            self.title = album.localizedName
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        if album.assets.count == 0{
            DispatchQueue.global(qos: .background).async { [weak welf = self] in
                welf?.album.loadAssets(completionHandler: { (_) in
                    DispatchQueue.main.async {
                        welf?.collectionView?.reloadData()
                        welf?.postAlbumLoadSetup()
                    }
                })
            }
        }
        else{
            postAlbumLoadSetup()
        }
    }

    @IBAction func selectAllButtonTapped(_ sender: UIBarButtonItem) {
        if selectedAssetsManager.selectedAssetCount(for: album) == album.assets.count {
            selectedAssetsManager.deselectAllAssets(for: album)
        }
        else {
            selectedAssetsManager.selectAllAssets(for: album)
        }
        
        updateSelectAllButtonTitle()
        collectionView?.reloadData()
    }
    
    func postAlbumLoadSetup() {
        activityIndicator.stopAnimating()
        
        // Hide "Select All" if current album has too many photos
        if selectedAssetsManager.willSelectingAllExceedTotalAllowed(for: album){
            selectAllButton.title = nil
            return
        }
        
        updateSelectAllButtonTitle()
    }
    
    func updateSelectAllButtonTitle() {
        if selectedAssetsManager.selectedAssetCount(for: album) == self.album.assets.count {
            selectAllButton.title = NSLocalizedString("ImagePicker/Button/DeselectAll", value: "Deselect All", comment: "Button title for de-selecting all selected photos")
        }
        else{
            selectAllButton.title = NSLocalizedString("ImagePicker/Button/SelectAll", value: "Select All", comment: "Button title for selecting all selected photos")
        }
    }
    
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
        
        if selectedAssetsManager.isSelected(asset, for: album){
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
        selectedAssetsManager.toggleSelected(asset, for: album)
        
        collectionView.reloadItems(at: [indexPath])
        
        updateSelectAllButtonTitle()
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
