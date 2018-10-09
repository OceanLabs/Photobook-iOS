//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotobookProductChangeDelegate: class {
    func didChangePhotobookProduct(_ photobookProduct: PhotobookProduct, assets: [Asset], album: Album?, albumManager: AlbumManager?)
    func didDeletePhotobookProduct()
}

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
        
    var currentProduct: PhotobookProduct?
    
    weak var delegate: PhotobookProductChangeDelegate?
    
    func reset() {
        currentProduct = nil
        delegate?.didDeletePhotobookProduct()
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
    
    func changedCurrentProduct(with assets: [Asset], album: Album?, albumManager: AlbumManager?) {
        delegate?.didChangePhotobookProduct(currentProduct!, assets: assets, album: album, albumManager: albumManager)
    }
}
