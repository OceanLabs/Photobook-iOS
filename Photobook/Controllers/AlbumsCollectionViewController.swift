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
    var assetCollectorController: AssetCollectorViewController!
    
    /// The height between the bottom of the image and bottom of the cell where the labels sit
    private let albumCellLabelsHeight: CGFloat = 50
    private let marginBetweenAlbums: CGFloat = 20
    
    var albumManager: AlbumManager!
    private let selectedAssetsManager = SelectedAssetsManager()
    var collectorMode: AssetCollectorMode = .selecting
    weak var addingDelegate: AssetCollectorAddingDelegate?
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAlbums()
        
        // Setup the Image Collector Controller
        assetCollectorController = AssetCollectorViewController.instance(fromStoryboardWithParent: self, selectedAssetsManager: selectedAssetsManager)
        assetCollectorController.mode = collectorMode
        assetCollectorController.delegate = self
        
        calcAndSetCellSize()
        
        // Listen to asset manager
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameSelected, object: selectedAssetsManager)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedAssetManagerCountChanged(_:)), name: SelectedAssetsManager.notificationNameDeselected, object: selectedAssetsManager)
        
        // Listen for album changes
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereReloaded(_:)), name: AssetsNotificationName.albumsWereReloaded, object: nil)
    }
    
    func loadAlbums() {
        albumManager.loadAlbums(completionHandler: { [weak welf = self] (errorMessage) in
            guard errorMessage == nil else {
                welf?.emptyScreenViewController.show(message: errorMessage!.message, title:errorMessage!.title, buttonTitle: errorMessage!.buttonTitle, buttonAction: errorMessage?.buttonAction)
                return
            }
            
            welf?.activityIndicator.stopAnimating()
            welf?.collectionView?.reloadData()
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh number of assets selected badges
        for cell in collectionView?.visibleCells ?? [] {
            guard let cell = cell as? AlbumCollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell)
            else { continue }
            
            let album = albumManager.albums[indexPath.item]
            let selectedAssetsCount = selectedAssetsManager.count(for: album)
            cell.selectedCountLabel.text = "\(selectedAssetsCount)"
            cell.selectedCountLabel.isHidden = selectedAssetsCount == 0
        }
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
        var usableSpace = collectionView.frame.size.width - marginBetweenAlbums
        if let insets = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset{
            usableSpace -= insets.left + insets.right
        }
        let cellWidth = usableSpace / 2.0
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: cellWidth, height: cellWidth + albumCellLabelsHeight)
    }
    
    func showAlbum(album: Album){
        let assetPickerController = self.storyboard?.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as! AssetPickerCollectionViewController
        assetPickerController.album = album
        assetPickerController.albumManager = albumManager
        assetPickerController.selectedAssetsManager = selectedAssetsManager
        assetPickerController.collectorMode = collectorMode
        assetPickerController.addingDelegate = addingDelegate
        
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
    
    @objc func albumsWereReloaded(_ notification: Notification) {
        guard let albumsChanged = notification.object as? [Album] else { return }
        var indexPathsChanged = [IndexPath]()
        
        for album in albumsChanged {
            guard let index = albumManager.albums.index(where: { $0.identifier == album.identifier }) else { continue }
            indexPathsChanged.append(IndexPath(item: index, section: 0))
        }
        
        collectionView?.reloadItems(at: indexPathsChanged)
    }
    
}

extension AlbumsCollectionViewController: AssetCollectorViewControllerDelegate {
    // MARK: AssetCollectorViewControllerDelegate
    
    func assetCollectorViewController(_ assetCollectorViewController: AssetCollectorViewController, didChangeHiddenStateTo hidden: Bool) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func assetCollectorViewControllerDidFinish(_ assetCollectorViewController: AssetCollectorViewController) {
        switch collectorMode {
        case .adding:
            addingDelegate?.didFinishAdding(assets: selectedAssetsManager.selectedAssets)
        default:
            let photobookViewController = storyboard?.instantiateViewController(withIdentifier: "PhotobookViewController") as! PhotobookViewController
            photobookViewController.selectedAssetsManager = selectedAssetsManager
            navigationController?.pushViewController(photobookViewController, animated: true)
        }
    }
}

extension AlbumsCollectionViewController{
    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumManager.albums.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCollectionViewCell", for: indexPath) as? AlbumCollectionViewCell else { return UICollectionViewCell() }
    
        let album = albumManager.albums[indexPath.item]
        cell.albumId = album.identifier
        
        let cellWidth = (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width ?? 0
        album.coverAsset(completionHandler: {(asset, error) in
            cell.albumCoverImageView.setAndFadeIn(asset: asset, size: CGSize(width: cellWidth, height: cellWidth), completionHandler: {
                return cell.albumId == album.identifier
            })
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
        if let assetCollectorViewController = assetCollectorController {
            height = assetCollectorViewController.viewHeight
        }
        return CGSize(width: collectionView.frame.size.width, height: height)
    }
}

extension AlbumsCollectionViewController{
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showAlbum(album: albumManager.albums[indexPath.item])
    }
}

extension AlbumsCollectionViewController: AlbumSearchResultsTableViewControllerDelegate {
    func searchDidSelect(_ album: Album) {
        showAlbum(album: album)
    }
    
    
}
