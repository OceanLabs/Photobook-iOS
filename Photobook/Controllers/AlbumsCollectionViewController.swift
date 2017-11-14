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
    
    /// The height between the bottom of the image and bottom of the cell where the labels sit
    private let albumCellLabelsHeight: CGFloat = 50
    private let marginBetweenAlbums: CGFloat = 20
    
    var albumManager: AlbumManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        albumManager.loadAlbums(completionHandler: { [weak welf = self] (error) in
            welf?.activityIndicator.stopAnimating()
            welf?.collectionView?.reloadData()
        })
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
        
        let cellWidth = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).width
        album.coverImage(size: CGSize(width: cellWidth, height: cellWidth), completionHandler: {(image, error) in
            guard cell.albumId == album.identifier else { return }
            cell.albumCoverImageView.image = image
        })
        cell.albumCoverImageView.layer.cornerRadius = 5
        
        cell.albumNameLabel.text = album.localizedName
        
        let totalNumberOfAssets = album.numberOfAssets
        cell.albumAssetsCountLabel.isHidden = totalNumberOfAssets == NSNotFound
        cell.albumAssetsCountLabel.text = "\(totalNumberOfAssets)"
        
        let selectedAssetsCount = SelectedAssetsManager.selectedAssets(album).count
        cell.selectedCountLabel.text = "\(selectedAssetsCount)"
        cell.selectedCountLabel.isHidden = selectedAssetsCount == 0
        cell.selectedCountLabel.layer.cornerRadius = cell.selectedCountLabel.frame.size.height / 2.0
        cell.selectedCountLabel.layer.masksToBounds = true
    
        return cell
    }

}

extension AlbumsCollectionViewController{
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let assetPickerController = self.storyboard?.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as? AssetPickerCollectionViewController else { return }
        assetPickerController.album = albumManager.albums[indexPath.item]
        
        self.navigationController?.pushViewController(assetPickerController, animated: true)
    }
}

extension AlbumsCollectionViewController: UICollectionViewDelegateFlowLayout{
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var usableSpace = collectionView.frame.size.width - marginBetweenAlbums;
        if let insets = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset{
            usableSpace -= insets.left + insets.right
        }
        let cellWidth = usableSpace / 2.0
        return CGSize(width: cellWidth, height: cellWidth + albumCellLabelsHeight)
    }
}

extension AlbumsCollectionViewController: AlbumSearchResultsTableViewControllerDelegate{
    func albumSearchResultsTableViewControllerDelegate(didSelect album: Album) {
        guard let assetPickerController = self.storyboard?.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as? AssetPickerCollectionViewController else { return }
        assetPickerController.album = album
        
        self.navigationController?.pushViewController(assetPickerController, animated: true)
    }
    
    
}
