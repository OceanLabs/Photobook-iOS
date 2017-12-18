//
//  AlbumsCollectionViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit


/// View Controller to show albums. It doesn't care about the source of those albums as long as they conform to the Album protocol.
class AlbumsCollectionViewController: UICollectionViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var imageCollectorController:AssetCollectorViewController?
    
    /// The height between the bottom of the image and bottom of the cell where the labels sit
    private let albumCellLabelsHeight: CGFloat = 50
    private let marginBetweenAlbums: CGFloat = 20
    
    var albumManager: AlbumManager!
    private let selectedAssetsManager = SelectedAssetsManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        albumManager.loadAlbums(completionHandler: { [weak welf = self] (error) in
            welf?.activityIndicator.stopAnimating()
            welf?.collectionView?.reloadData()
        })
        
        // Setup the Image Collector Controller
        imageCollectorController = AssetCollectorViewController.instance(fromStoryboardWithParent: self, selectedAssetsManager: selectedAssetsManager)
        imageCollectorController?.delegate = self
        
        calcAndSetCellSize()
        
        //listen to asset manager
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameSelected, object: selectedAssetsManager)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameDeselected, object: selectedAssetsManager)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh number of assets selected badges
        collectionView?.reloadData()
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        let searchResultsViewController = self.storyboard?.instantiateViewController(withIdentifier: "AlbumSearchResultsTableViewController") as! AlbumSearchResultsTableViewController
        searchResultsViewController.delegate = self
        searchResultsViewController.albums = self.albumManager.albums
        
        let searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = searchResultsViewController
        searchController.searchBar.placeholder = NSLocalizedString("Albums/Search/BarPlaceholder", value: "Search Albums", comment: "Search bar placeholder text")
        searchController.searchBar.barTintColor = UIColor.white
        searchResultsViewController.searchBar = searchController.searchBar
        
        definesPresentationContext = true
        present(searchController, animated: true, completion: nil)
    }
    
    func calcAndSetCellSize(){
        // Calc the cell size
        guard let collectionView = collectionView else { return }
        var usableSpace = collectionView.frame.size.width - marginBetweenAlbums;
        if let insets = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset{
            usableSpace -= insets.left + insets.right
        }
        let cellWidth = usableSpace / 2.0
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: cellWidth, height: cellWidth + albumCellLabelsHeight)
    }
    
    func showAlbum(album: Album){
        guard let assetPickerController = self.storyboard?.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as? AssetPickerCollectionViewController else { return }
        assetPickerController.album = album
        assetPickerController.albumManager = albumManager
        assetPickerController.selectedAssetsManager = selectedAssetsManager
        
        self.navigationController?.pushViewController(assetPickerController, animated: true)
    }
    
    @objc private func selectedAssetManagerCountChanged(_ notification: NSNotification) {
        guard let assets = notification.userInfo?[SelectedAssetsManager.notificationUserObjectKeyAssets] as? [Asset], let collectionView = collectionView else {
            return
        }
        var indexPathsToReload = [IndexPath]()
        for asset in assets {
            if let index = albumManager.albums.index(where: { (album) -> Bool in
                return album.identifier == asset.albumIdentifier
            }) {
                //check if indexpath is already added
                if indexPathsToReload.index(where: { (indexPath) -> Bool in
                    return indexPath.row == index
                }) == nil {
                    //not added yet, add
                    indexPathsToReload.append(IndexPath(row: index, section: 0))
                }
            }
        }
        
        collectionView.reloadItems(at: indexPathsToReload)
    }
    
}

extension AlbumsCollectionViewController: AssetCollectorViewControllerDelegate {
    // MARK: - AssetCollectorViewControllerDelegate
    
    func assetCollectorViewController(_ assetCollectorViewController: AssetCollectorViewController, didChangeHiddenStateTo hidden: Bool) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func imageCollectorViewController(_ imageCollectorViewController: AssetCollectorViewController, didFinishWithAssets: [Asset]) {
        guard let photobookViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoBookViewController") as? PhotoBookViewController else { return }
        photobookViewController.selectedAssetsManager = selectedAssetsManager
        navigationController?.pushViewController(photobookViewController, animated: true)
    }
}

extension AlbumsCollectionViewController{
    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumManager.albums.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCollectionViewCell", for: indexPath) as? AlbumCollectionViewCell else { return UICollectionViewCell() }
    
        let album = albumManager.albums[indexPath.item]
        cell.albumId = album.identifier
        cell.albumCoverImageView.image = nil
        
        let cellWidth = (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width ?? 0
        album.coverImage(size: CGSize(width: cellWidth, height: cellWidth), completionHandler: {(image, error) in
            guard cell.albumId == album.identifier else { return }
            cell.albumCoverImageView.image = image
        })
        
        cell.albumNameLabel.text = album.localizedName
        
        let totalNumberOfAssets = album.numberOfAssets
        cell.albumAssetsCountLabel.isHidden = totalNumberOfAssets == NSNotFound
        cell.albumAssetsCountLabel.text = "\(totalNumberOfAssets)"
        
        let selectedAssetsCount = selectedAssetsManager.count(for: album)
        cell.selectedCountLabel.text = "\(selectedAssetsCount)"
        cell.selectedCountLabel.isHidden = selectedAssetsCount == 0
        cell.selectedCountLabel.cornerRadius = cell.selectedCountLabel.frame.size.height / 2.0
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
            footerView.backgroundColor = UIColor.clear
            return footerView
            
        default:
            assert(false, "Unexpected element kind")
        }
        
        return UICollectionReusableView(frame: CGRect())

    }
    
}

extension AlbumsCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height:CGFloat = 0
        if let imageCollectorVC = imageCollectorController {
            height = imageCollectorVC.viewHeight
        }
        return CGSize(width: collectionView.frame.size.width, height: height)
    }
}

extension AlbumsCollectionViewController{
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showAlbum(album: albumManager.albums[indexPath.item])
    }
}

extension AlbumsCollectionViewController: AlbumSearchResultsTableViewControllerDelegate{
    func searchDidSelect(_ album: Album) {
        showAlbum(album: album)
    }
    
    
}
