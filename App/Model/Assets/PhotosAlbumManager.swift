//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Photos
import Photobook

class PhotosAlbumManager: NSObject, AlbumManager {
    
    private struct Constants {
        static let permissionsTitle = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedTitle",
                                                        value: "Permissions Required",
                                                        comment: "Title shown when the photo library access has been disabled")
        static let permissionsMessage = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedMessage",
                                                          value: "Photo access has been restricted, but it's needed to create beautiful photo books.\nYou can turn it back on in the system settings.",
                                                          comment: "Message shown when the photo library access has been disabled")
        static let permissionsButtonTitle = NSLocalizedString("Controllers/StoriesviewController/PermissionDeniedSettingsButton",
                                                              value: "Open Settings",
                                                              comment: "Button title to direct the user to the app permissions screen in the phone settings")
    }
    
    var albums = [Album]()
    var hasMoreAlbumsToLoad = false
    let title = NSLocalizedString("Albums/Title", value: "Albums", comment: "Title for the Albums screen")
    static let imageManager = PHCachingImageManager()
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    func loadAlbums(completionHandler: ((Error?) -> Void)?) {
        guard albums.isEmpty else { completionHandler?(nil); return }
        
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            let errorMessage = ActionableErrorMessage(title: Constants.permissionsTitle, message: Constants.permissionsMessage, buttonTitle: Constants.permissionsButtonTitle, buttonAction: {
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(appSettings)
                    }
                }
            }, dismissErrorPromptAfterAction: false)
            completionHandler?(errorMessage)
            return
        }
        
        DispatchQueue.global(qos: .default).async {
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
                if !album.assets.isEmpty {
                    albums.append(album)
                }
                
            }
            
            // Get Favorites album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if !album.assets.isEmpty {
                    albums.append(album)
                }
            }
            
            // Get Selfies album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if !album.assets.isEmpty {
                    albums.append(album)
                }
            }
            
            // Get Portrait album
            if #available(iOS 10.2, *) {
                if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumDepthEffect, options: options).firstObject{
                    let album = PhotosAlbum(collection)
                    
                    // Load assets here so that we know the number of assets in this album
                    album.loadAssetsFromPhotoLibrary()
                    if !album.assets.isEmpty {
                        albums.append(album)
                    }
                }
            }
            
            // Get Panoramas album
            if let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: options).firstObject{
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if !album.assets.isEmpty {
                    albums.append(album)
                }
            }
            
            // Get User albums
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            collections.enumerateObjects({ (collection, _, _) in
                guard collection.estimatedAssetCount != 0 else { return }
                let album = PhotosAlbum(collection)
                
                // Load assets here so that we know the number of assets in this album
                album.loadAssetsFromPhotoLibrary()
                if !album.assets.isEmpty {
                    albums.append(album)
                }
            })
            
            self.albums = albums
            
            DispatchQueue.main.async(execute: {() -> Void in
                completionHandler?(nil)
            })
        }
    }
    
    func loadNextBatchOfAlbums(completionHandler: ((Error?) -> Void)?) {
        // Maybe we can use this to load user albums after showing the system ones
    }
    
    func stopCachingImagesForAllAssets() {
        PhotosAlbumManager.imageManager.stopCachingImagesForAllAssets()
    }
    
    func startCachingImages(for assets: [PhotobookAsset], targetSize: CGSize) {
        var phAssets = [PHAsset]()
        assets.forEach {
            if let phAsset = $0.phAsset { phAssets.append(phAsset) }
        }
        PhotosAlbumManager.imageManager.startCachingImages(for: phAssets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
    
    func stopCachingImages(for assets: [PhotobookAsset], targetSize: CGSize) {
        var phAssets = [PHAsset]()
        assets.forEach {
            if let phAsset = $0.phAsset { phAssets.append(phAsset) }
        }
        PhotosAlbumManager.imageManager.stopCachingImages(for: phAssets, targetSize: targetSize, contentMode: .aspectFill, options: nil)
    }
}

extension PhotosAlbumManager: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        var albumChanges = [AlbumChange]()
        
        DispatchQueue.main.sync {
            var albumsToLoadAssets = [Album]()
            for album in albums {
                guard let album = album as? PhotosAlbum else { continue }
                let (assetsInserted, assetsRemoved) = album.changedAssets(for: changeInstance)
                
                if let assetsInserted = assetsInserted, let assetsRemoved = assetsRemoved,
                    !assetsInserted.isEmpty || !assetsRemoved.isEmpty {
                    
                    var indexesRemoved = [Int]()
                    for assetRemoved in assetsRemoved {
                        if let index = album.assets.index(where: { $0.identifier == assetRemoved.identifier}) {
                            indexesRemoved.append(index)
                        }
                    }
                    
                    albumChanges.append(AlbumChange(albumIdentifier: album.identifier, assetsRemoved: assetsRemoved, assetsInserted: assetsInserted, indexesRemoved: indexesRemoved))
                    albumsToLoadAssets.append(album)
                }
            }
            
            if !albumChanges.isEmpty {
                let dispatchGroup = DispatchGroup()
                
                albumsToLoadAssets.forEach {
                    dispatchGroup.enter()
                    $0.loadAssets(completionHandler: { _ in
                        dispatchGroup.leave()
                    })
                }
                
                dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                    NotificationCenter.default.post(name: AlbumManagerNotificationName.albumsWereUpdated, object: albumChanges)
                    PhotobookSDK.shared.albumsWereUpdated(albumChanges)
                })                
            }
        }
    }
}

extension PhotosAlbumManager: PickerAnalytics {
    var selectingPhotosScreenName: Analytics.ScreenName { return .albums }
    var addingMorePhotosScreenName: Analytics.ScreenName { return .albumsAddingMorePhotos }
}
