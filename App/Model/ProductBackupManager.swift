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
