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

enum AssetDataSourceException: Error {
    case unsupported(details: String)
}

class AssetDataSourceBackupManager {
    
    private struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let dataSourceBackupFile = photobookDirectory.appending("AssetDataSource.dat")
    }
    
    static let shared = AssetDataSourceBackupManager()

    func restoreBackup() -> AssetDataSourceBackup? {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: Storage.dataSourceBackupFile) as? Data else {
            print("AssetDataSourceBackupManager: could not unarchive backup file")
            return nil
        }
        guard let unarchivedBackup = try? PropertyListDecoder().decode(AssetDataSourceBackup.self, from: unarchivedData) else {
            print("AssetDataSourceBackupManager: could not decode backup file")
            return nil
        }
        return unarchivedBackup
    }
    
    func saveBackup(_ dataSourceBackup: AssetDataSourceBackup) {
        if !FileManager.default.fileExists(atPath: Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("ProductManager: could not create photobook directory")
            }
        }
        
        guard let dataSourceBackupData = try? PropertyListEncoder().encode(dataSourceBackup) else {
            print("ProductManager: failed to encode product backup")
            return
        }
        
        if !NSKeyedArchiver.archiveRootObject(dataSourceBackupData, toFile: Storage.dataSourceBackupFile) {
            print("ProductManager: failed to archive product backup")
        }
    }
    
    func deleteBackup() {
        _ = try? FileManager.default.removeItem(atPath: Storage.dataSourceBackupFile)
    }
}

class AssetDataSourceBackup: Codable {
    
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
                throw AssetDataSourceException.unsupported(details: "AssetDataSourceBackup: Datasource type not valid")
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
    
    var album: Album?
    var albumManager: AlbumManager?

    private enum CodingKeys: String, CodingKey {
        case album, albumManager
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

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

