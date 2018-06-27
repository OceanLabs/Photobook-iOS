//
//  AlbumsCollectionViewController+Facebook.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

extension AlbumsCollectionViewController {
    
    static func facebookAlbumsCollectionViewController() -> AlbumsCollectionViewController {
        let albumViewController = mainStoryboard.instantiateViewController(withIdentifier: "AlbumsCollectionViewController") as! AlbumsCollectionViewController
        albumViewController.albumManager = FacebookAlbumManager()
        albumViewController.prepareToHandleLogout(accountManager: FacebookClient.shared)
        return albumViewController
    }
}
