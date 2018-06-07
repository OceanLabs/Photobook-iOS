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
    
    var minimumRequiredPages: Int {
        return currentProduct?.template.minPages ?? 20
    }

    var maximumAllowedPages: Int {
        return currentProduct?.template.maxPages ?? 70
    }
        
    private(set) var currentProduct: PhotobookProduct?
    
    func reset() {
        currentProduct = nil
    }
    
    /// Requests the photobook details so the user can start building their photobook
    ///
    /// - Parameter completion: Completion block with an optional error
    func initialise(completion:((Error?)->())?) {
        apiManager.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, error) in
            guard error == nil else {
                completion?(error!)
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
}
