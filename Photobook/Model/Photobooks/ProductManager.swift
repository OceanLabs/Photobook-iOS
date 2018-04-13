//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class ProductManager {
    
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
    
    // List of all available upsell options
    private(set) var upsellOptions: [UpsellOption]?
    
    var minimumRequiredAssets: Int {
        let defaultMinimum = 20
        
        return currentProduct?.template.minimumRequiredAssets ?? ProductManager.shared.products?.first?.minimumRequiredAssets ?? defaultMinimum
    }
    var maximumAllowedAssets: Int {
        // TODO: get this from the photobook
        return 70
    }
    
    var currentProduct: PhotobookProduct?
    
    func reset() {
        currentProduct = nil
    }
    
    /// Requests the photobook details so the user can start building their photobook
    ///
    /// - Parameter completion: Completion block with an optional error
    func initialise(completion:((Error?)->())?) {
        apiManager.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, upsellOptions, error) in
            guard error == nil else {
                completion?(error!)
                return
            }
            
            welf?.products = photobooks
            welf?.layouts = layouts
            welf?.upsellOptions = upsellOptions
            
            completion?(nil)
        }
    }
    
    func coverLayouts(for photobook: PhotobookTemplate) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.coverLayouts.contains($0.id) }
    }
    
    func layouts(for photobook: PhotobookTemplate) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.layouts.contains($0.id) }
    }
    
    /// Loads the user's photobook details from disk
    func loadUserPhotobook() {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: OrderManager.Storage.photobookBackupFile) as? Data else {
            print("ProductManager: failed to unarchive product")
            return
        }
        guard let unarchivedProduct = try? PropertyListDecoder().decode(PhotobookProduct.self, from: unarchivedData) else {
            print("ProductManager: decoding of product failed")
            return
        }
        
        currentProduct = unarchivedProduct
        unarchivedProduct.restoreUploads()
    }
    
    
    /// Saves the user's photobook details to disk
    func saveUserPhotobook() {
        guard let rootObject = currentProduct else { return }
        
        guard let data = try? PropertyListEncoder().encode(rootObject) else {
            fatalError("ProductManager: encoding of product failed")
        }
        
        if !FileManager.default.fileExists(atPath: OrderManager.Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: OrderManager.Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("ProductManager: could not save photobook")
            }
        }
        
        let saved = NSKeyedArchiver.archiveRootObject(data, toFile: OrderManager.Storage.photobookBackupFile)
        if !saved {
            print("ProductManager: failed to archive product")
        }
    }

}
