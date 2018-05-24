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
    
    var minimumRequiredAssets: Int {
        let defaultMinimum = 20
        
        return currentProduct?.template.minimumRequiredAssets ?? ProductManager.shared.products?.first?.minimumRequiredAssets ?? defaultMinimum
    }
    var maximumAllowedAssets: Int {
        // TODO: get this from the photobook
        return 70
    }
    
    private(set) var currentProduct: PhotobookProduct? {
        willSet {
            upsoldTemplate = nil
            upsoldPayload = nil
        }
    }
    var upsoldTemplate: PhotobookTemplate?
    var upsoldPayload: [String: Any]?
    
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
    
    func applyUpsells(_ upsells:[UpsellOption], completionHandler: @escaping (_ summary: OrderSummary?, _ error: Error?) -> Void) {
        guard let currentProduct = currentProduct else {
            completionHandler(nil, nil)
            return
        }
        
        apiManager.applyUpsells(product: currentProduct, upsellOptions: upsells) { (summary, upsoldTemplate, productPayload, error) in
            self.upsoldTemplate = upsoldTemplate
            self.upsoldPayload = productPayload
            
            completionHandler(summary, error)
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
    
    func setCurrentProduct(with photobook: PhotobookTemplate, assets: [Asset]) -> PhotobookProduct? {
        currentProduct = PhotobookProduct(template: photobook, assets: assets, productManager: self)
        return currentProduct
    }
}
