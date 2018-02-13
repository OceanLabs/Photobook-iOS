//
//  PhotosAlbumManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotosAlbumManager: NSObject, AlbumManager {
    
    private struct Constants {
        static let permissionsTitle = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedTitle",
                                                        value: "Permissions Required",
                                                        comment: "Title shown when the photo library access has been disabled")
        static let permissionsMessage = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedMessage",
                                                          value: "Photo access has been restricted, but it's needed to create beautiful photo books.\nYou can turn it back on in the system settings",
                                                          comment: "Message shown when the photo library access has been disabled")
        static let permissionsButtonTitle = NSLocalizedString("Controllers/StoriesviewController/PermissionDeniedSettingsButton",
                                                              value: "Open Settings",
                                                              comment: "Button title to direct the user to the app permissions screen in the phone settings")
    }
    
    var albums:[Album] = [Album]()
    static let imageManager = PHCachingImageManager()
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    func loadAlbums(completionHandler: ((ErrorMessage?) -> Void)?) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            let errorMessage = ErrorMessage(title: Constants.permissionsTitle, message: Constants.permissionsMessage, buttonTitle: Constants.permissionsButtonTitle, buttonAction: {
                if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            })
            completionHandler?(errorMessage)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            var albums = [Album]()
            
            let options = PHFetchOptions()
            options.wantsIncrementalChangeDetails = false
            options.includeHiddenAssets = false
            options.includeAllBurstAssets = false
            
            // Get "All Photos" album
            let fetchedResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options)
            if let collection = fetchedResult.firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    albums.append(album)
                }
                
            }
            
            // Get Favorites album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    albums.append(album)
                }
            }
            
            // Get Selfies album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    albums.append(album)
                }
            }
            
            // Get Portrait album
            if #available(iOS 10.2, *) {
                if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumDepthEffect, options: options).firstObject{
                    let album = PhotosAlbum(collection)
                    
                    // Load assets here so that we know the number of assets in this album
                    album.loadAssetsFromPhotoLibrary()
                    if album.assets.count > 0 {
                        albums.append(album)
                    }
                }
            }
            
            // Get Panoramas album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if album.assets.count > 0 {
                    albums.append(album)
                }
            }
            
            // Get User albums
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            collections.enumerateObjects({ (collection, _, _) in
                guard collection.estimatedAssetCount != 0 else { return }
                let album = PhotosAlbum(collection)
                albums.append(album)
            })
            
            self.albums = albums
            
            DispatchQueue.main.async(execute: {() -> Void in
                completionHandler?(nil)
            })
        }
    }
    
    func stopCachingImagesForAllAssets() {
        PhotosAlbumManager.imageManager.stopCachingImagesForAllAssets()
    }
    
    func startCachingImages(for assets: [Asset], targetSize: CGSize) {
        PhotosAlbumManager.imageManager.startCachingImages(for: PhotosAsset.photosAssets(from: assets), targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    func stopCachingImages(for assets: [Asset], targetSize: CGSize) {
        PhotosAlbumManager.imageManager.stopCachingImages(for: PhotosAsset.photosAssets(from: assets), targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    

}

extension PhotosAlbumManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        var changedAlbums = [Album]()
        
        DispatchQueue.main.sync {
            for album in albums {
                guard let album = album as? PhotosAlbum,
                    let fetchedResult = album.fetchedAssets
                    else { continue }
                if let changeDetails = changeInstance.changeDetails(for: fetchedResult), changeDetails.removedObjects.count > 0 || changeDetails.insertedObjects.count > 0 {
                    changedAlbums.append(album)
                }
            }
            
            if changedAlbums.count > 0 {
                let dispatchGroup = DispatchGroup()
                
                for album in changedAlbums {
                    dispatchGroup.enter()
                    album.loadAssets(completionHandler: { _ in
                        dispatchGroup.leave()
                    })
                }
                
                dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                   NotificationCenter.default.post(name: AssetsNotificationName.albumsWereReloaded, object: changedAlbums)
                })
                
            }
        }
    }
    
}
