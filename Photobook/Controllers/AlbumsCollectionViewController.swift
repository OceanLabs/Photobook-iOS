//
//  AlbumsCollectionViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AlbumsCollectionViewController: UICollectionViewController {
    
    var searchController: UISearchController?
    
    let albumCellLabelsHeight = CGFloat(50)
    let marginBetweenAlbums = CGFloat(20)
    
    let albumManager: AlbumManager/*!*/ = PhotosAlbumManager() //TODO: this should be set from outside of this class

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        let searchResultsViewController = self.storyboard?.instantiateViewController(withIdentifier: "AlbumSearchResultsTableViewController") as! AlbumSearchResultsTableViewController
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController?.searchResultsUpdater = searchResultsViewController
        searchController?.searchBar.placeholder = "Search Albums"
        searchController?.searchBar.barTintColor = UIColor.white
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        
        albumManager.loadAlbums(completionHandler: {(error) in
            self.collectionView?.reloadData()
            searchResultsViewController.albums = self.albumManager.albums
        })
    }
    
    @IBAction func searchIconTapped(_ sender: Any) {
        guard let searchController = searchController else { return }
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
