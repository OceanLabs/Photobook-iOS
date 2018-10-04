//
//  PhotobookProductBackupManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 03/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

class PhotobookProductBackupManager {
    
    private struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Photobook") + "/")
        static let productBackupFile = photobookDirectory.appending("PhotobookProduct.dat")
    }

    static let shared = PhotobookProductBackupManager()
    
    func restoreBackup() -> PhotobookProductBackup? {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: Storage.productBackupFile) as? Data else {
            print("ProductManager: could not unarchive backup file")
            return nil
        }
        guard let unarchivedBackup = try? PropertyListDecoder().decode(PhotobookProductBackup.self, from: unarchivedData) else {
            print("ProductManager: could not decode backup file")
            return nil
        }
        return unarchivedBackup
    }
    
    func saveBackup(_ productBackup: PhotobookProductBackup) {
        if !FileManager.default.fileExists(atPath: Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("ProductManager: could not create photobook directory")
            }
        }
        
        guard let productBackupData = try? PropertyListEncoder().encode(productBackup) else {
            print("ProductManager: failed to encode product backup")
            return
        }
        
        if !NSKeyedArchiver.archiveRootObject(productBackupData, toFile: Storage.productBackupFile) {
            print("ProductManager: failed to archive product backup")
        }
    }
    
    func deleteBackup() {
        _ = try? FileManager.default.removeItem(atPath: Storage.productBackupFile)
    }
}

class PhotobookProductBackup: Codable {
    
    enum Datasource: Codable {
        case unsupported
        case photos(PhotosAlbum?)
        case facebook(FacebookAlbum?)
        case instagram
        
        private enum CodingKeys: String, CodingKey {
            case type, album
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .photos(let photosAlbum):
                try container.encode("photos", forKey: .type)
                try container.encode(photosAlbum, forKey: .album)
            case .facebook(let facebookAlbum):
                try container.encode("facebook", forKey: .type)
                try container.encode(facebookAlbum, forKey: .album)
            case .instagram:
                try container.encode("instagram", forKey: .type)
            default:
                throw AssetLoadingException.unsupported(details: "ProductBackup: Datasource type not valid")
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "photos":
                let album = try? container.decode(PhotosAlbum.self, forKey: .album)
                self = .photos(album)
            case "facebook":
                let album = try? container.decode(FacebookAlbum.self, forKey: .album)
                self = .facebook(album)
            case "instagram":
                self = .instagram
            default:
                self = .unsupported
            }
        }
    }
    
    var product: PhotobookProduct!
    var assets: [Asset]!
    var album: Album?
    var albumManager: AlbumManager?
    
    private enum CodingKeys: String, CodingKey {
        case product, assets, album, albumManager
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(product, forKey: .product)
        
        // Encode assets
        var assetsData: Data? = nil
        if let assets = assets as? [PhotosAsset] {
            assetsData = try PropertyListEncoder().encode(assets)
        } else if let assets = assets as? [URLAsset] {
            assetsData = try PropertyListEncoder().encode(assets)
        } else if let assets = assets as? [ImageAsset] {
            assetsData = try PropertyListEncoder().encode(assets)
        } else if let assets = assets as? [PhotosAssetMock] {
            assetsData = try PropertyListEncoder().encode(assets)
        }
        try container.encode(assetsData, forKey: .assets)
        
        // Encode album
        if let album = album as? PhotosAlbum {
            try container.encode(Datasource.photos(album), forKey: .album)
        } else if let album = album as? FacebookAlbum {
            try container.encode(Datasource.facebook(album), forKey: .album)
        } else if let _ = album as? InstagramAlbum {
            try container.encode(Datasource.instagram, forKey: .album)
        }
        
        // Encode album manager type
        if let _ = albumManager as? PhotosAlbumManager {
            try container.encode(Datasource.photos(nil), forKey: .albumManager)
        } else if let _ = albumManager as? FacebookAlbumManager {
            try container.encode(Datasource.facebook(nil), forKey: .albumManager)
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        product = try? values.decode(PhotobookProduct.self, forKey: .product)
        
        if let assetsData = try values.decodeIfPresent(Data.self, forKey: .assets) {
            if let loadedAsset = try? PropertyListDecoder().decode([URLAsset].self, from: assetsData) {
                assets = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode([ImageAsset].self, from: assetsData) {
                assets = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode([PhotosAsset].self, from: assetsData) { // Keep the PhotosAsset case last because otherwise it triggers NSPhotoLibraryUsageDescription crash if not present, which might not be needed
                assets = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode([PhotosAssetMock].self, from: assetsData) {
                assets = loadedAsset
            }
        }
        
        if let albumDatasource = try values.decodeIfPresent(Datasource.self, forKey: .album) {
            switch albumDatasource {
            case .photos(let photosAlbum): album = photosAlbum
            case .facebook(let facebookAlbum): album = facebookAlbum
            case .instagram: album = InstagramAlbum()
            default: break
            }
            album?.loadAssets(completionHandler: nil)
        }
        
        if let albumManagerDatasource = try values.decodeIfPresent(Datasource.self, forKey: .albumManager) {
            switch albumManagerDatasource {
            case .photos(_): albumManager = PhotosAlbumManager()
            case .facebook(_): albumManager = FacebookAlbumManager()
            default: break
            }
            albumManager?.loadAlbums(completionHandler: nil)
        }
    }
}
