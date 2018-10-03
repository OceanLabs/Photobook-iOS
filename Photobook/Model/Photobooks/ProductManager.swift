//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class ProductManager {
    
    private struct Storage {
        // TEMP: Move to globals
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let productBackupFile = photobookDirectory.appending("Product.dat")
    }

    static let shared = ProductManager()
    
    private lazy var apiManager = PhotobookAPIManager()
    
    #if DEBUG
    convenience init(apiManager: PhotobookAPIManager) {
        self.init()
        self.apiManager = apiManager
    }
    #endif
    
    // Public info about photobook products
    private(set) var products: [PhotobookTemplate]?
    
    // List of all available layouts
    private(set) var layouts: [Layout]?
    
    var minimumRequiredPages: Int {
        if let minPages = currentProduct?.photobookTemplate.minPages { return minPages }
        if let minPages = products?.first?.minPages { return minPages }
        return 20
    }

    var maximumAllowedPages: Int {
        if let maxPages = currentProduct?.photobookTemplate.maxPages { return maxPages }
        if let maxPages = products?.first?.maxPages { return maxPages }
        return 100
    }
        
    private(set) var currentProduct: PhotobookProduct?
    
    func reset() {
        currentProduct = nil
    }
    
    /// Requests the photobook details so the user can start building their photobook
    ///
    /// - Parameter completion: Completion block with an optional error
    func initialise(completion:((ErrorMessage?)->())?) {
        apiManager.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, error) in
            guard error == nil else {
                if let error = error as? APIClientError, case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                completion?(ErrorMessage(error!))
                return
            }
            
            welf?.products = photobooks
            welf?.layouts = layouts
            
            completion?(nil)
        }
    }
        
    private func coverLayouts(for photobook: PhotobookTemplate) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.coverLayouts.contains($0.id) }
    }
    
    private func layouts(for photobook: PhotobookTemplate) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.layouts.contains($0.id) }
    }
    
    func restoreCurrentProduct() -> [Asset]? {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: Storage.productBackupFile) as? Data else {
            print("ProductManager: could not unarchive backup file")
            return nil
        }
        guard let unarchivedBackup = try? PropertyListDecoder().decode(ProductBackup.self, from: unarchivedData) else {
            print("ProductManager: could not decode backup file")
            return nil
        }
        currentProduct = unarchivedBackup.product
        return unarchivedBackup.assets
    }
    
    func saveCurrentProduct(with assets: [Asset]) {
        if !FileManager.default.fileExists(atPath: Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("ProductManager: could not create photobook directory")
            }
        }

        let productBackup = ProductBackup()
        productBackup.product = currentProduct
        productBackup.assets = assets
        
        guard let productBackupData = try? PropertyListEncoder().encode(productBackup) else {
            print("ProductManager: failed to encode product backup")
            return
        }
        
        if !NSKeyedArchiver.archiveRootObject(productBackupData, toFile: Storage.productBackupFile) {
            print("ProductManager: failed to archive product backup")
        }
    }
    
    func setProduct(_ product: PhotobookProduct, with template: PhotobookTemplate) {
        guard let availableCoverLayouts = coverLayouts(for: template),
            let availableLayouts = layouts(for: template)
        else { return }
        
        product.setTemplate(template, coverLayouts: availableCoverLayouts, layouts: availableLayouts)
    }
    
    func setCurrentProduct(with template: PhotobookTemplate, assets: [Asset]? = nil) -> PhotobookProduct? {
        // Replacing template
        if currentProduct != nil {
            setProduct(currentProduct!, with: template)
        } else if let assets = assets { // First time or replacing product
            guard let availableCoverLayouts = coverLayouts(for: template),
                let availableLayouts = layouts(for: template)
            else { return currentProduct }

            currentProduct = PhotobookProduct(template: template, assets: assets, coverLayouts: availableCoverLayouts, layouts: availableLayouts)
        }
        
        return currentProduct
    }
}

class ProductBackup: Codable {
    var product: PhotobookProduct!
    var assets: [Asset]!
    
    private enum CodingKeys: String, CodingKey {
        case product, assets
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(product, forKey: .product)
        
        var data: Data? = nil
        if let assets = assets as? [PhotosAsset] {
            data = try PropertyListEncoder().encode(assets)
        } else if let assets = assets as? [URLAsset] {
            data = try PropertyListEncoder().encode(assets)
        } else if let assets = assets as? [ImageAsset] {
            data = try PropertyListEncoder().encode(assets)
        } else if let assets = assets as? [PhotosAssetMock] {
            data = try PropertyListEncoder().encode(assets)
        }
        try container.encode(data, forKey: .assets)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        product = try? values.decode(PhotobookProduct.self, forKey: .product)
        
        if let data = try values.decodeIfPresent(Data.self, forKey: .assets) {
            if let loadedAsset = try? PropertyListDecoder().decode([URLAsset].self, from: data) {
                assets = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode([ImageAsset].self, from: data) {
                assets = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode([PhotosAsset].self, from: data) { // Keep the PhotosAsset case last because otherwise it triggers NSPhotoLibraryUsageDescription crash if not present, which might not be needed
                assets = loadedAsset
            } else if let loadedAsset = try? PropertyListDecoder().decode([PhotosAssetMock].self, from: data) {
                assets = loadedAsset
            }
        }
    }
}

