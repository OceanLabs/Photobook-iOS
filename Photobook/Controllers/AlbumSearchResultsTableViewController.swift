//
//  AlbumSearchResultsTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AlbumSearchResultsTableViewController: UITableViewController {
    
    var albums: [Album]! {
        didSet{
            filteredAlbums = albums
        }
    }
    var filteredAlbums: [Album]!
    var searchQuery: String?
}

extension AlbumSearchResultsTableViewController{
    // MARK: - UITableView DataSource & Delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredAlbums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumSearchResultsTableViewCell", for: indexPath) as? AlbumSearchResultsTableViewCell else { return UITableViewCell() }
        let album = filteredAlbums[indexPath.item]
        cell.albumId = album.identifier
        
        album.coverImage(size: CGSize(width: tableView.rowHeight, height: tableView.rowHeight), completionHandler: {(image, _) in
            guard cell.albumId == album.identifier else { return }
            cell.albumCoverImageView.image = image
        })
        
        cell.imageCountLabel.text = "\(album.numberOfAssets)"
        
        // Color the matched part of the name black and gray out the rest
        if let searchQuery = self.searchQuery, searchQuery != "", let albumName = album.localizedName, let matchRange = albumName.lowercased().range(of: searchQuery){
            let attributedString = NSMutableAttributedString(string: albumName, attributes: [.foregroundColor: UIColor.gray])
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(matchRange, in: albumName))
            
            cell.albumNameLabel.attributedText = attributedString
        }
        else{
            cell.albumNameLabel.text = album.localizedName
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumSearchResultsTableViewCell else { return }
        cell.albumCoverImageView.image = nil
    }

}

extension AlbumSearchResultsTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        self.searchQuery = searchController.searchBar.text?.lowercased()
        filteredAlbums = albums.filter({(album) -> Bool in
            guard let albumName = album.localizedName?.lowercased() else { return false }
            guard let searchQuery = self.searchQuery, searchQuery != "" else { return true }
            
            return albumName.contains(searchQuery)
        })
        
        // Avoid reloading when this vc is first shown
        if !(tableView.numberOfRows(inSection: 0) == albums.count && albums.count == filteredAlbums.count){
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        searchController.searchResultsController?.view.isHidden = false
    }
}
