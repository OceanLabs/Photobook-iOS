//
//  PhotosAlbumManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotosAlbumManager: AlbumManager {
    
    var albums:[Album] = [Album]()
    
    func loadAlbums(completionHandler: ((Error?) -> Void)?) {
        let options : PHFetchOptions = PHFetchOptions()
        options.wantsIncrementalChangeDetails = false
        options.includeHiddenAssets = false
        options.includeAllBurstAssets = false
        
        // Get "All Photos" album
        if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options).firstObject{
            let album = PhotosAlbum(collection)
            album.loadAssets(completionHandler: nil)
            albums.append(album)
        }
        
        // Get Favorites album
        if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: options).firstObject{
            let album = PhotosAlbum(collection)
            album.loadAssets(completionHandler: nil)
            albums.append(album)
        }
        
        // Get Selfies album
        if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: options).firstObject{
            let album = PhotosAlbum(collection)
            album.loadAssets(completionHandler: nil)
            albums.append(album)
        }
        
        // Get Portrait album
        if #available(iOS 10.2, *) {
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumDepthEffect, options: options).firstObject{
                let album = PhotosAlbum(collection)
                album.loadAssets(completionHandler: nil)
                albums.append(album)
            }
        }
        
        // Get Panoramas album
        if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: options).firstObject{
            let album = PhotosAlbum(collection)
            album.loadAssets(completionHandler: nil)
            albums.append(album)
        }
        
        // Get User albums
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        collections.enumerateObjects({ (collection, index, stop) in
            guard collection.estimatedAssetCount != 0 else { return }
            let album = PhotosAlbum(collection)
            self.albums.append(album)
        })
        
        completionHandler?(nil)
        
    }
    

}
