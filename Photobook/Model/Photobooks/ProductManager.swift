//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

enum ProductColor {
    case white, black
}

class ProductManager {
    static let shared = ProductManager()
    
    private var apiManager = PhotobookAPIManager.shared
    
    #if DEBUG
    convenience init(apiManager: PhotobookAPIManager) {
        self.init()
        self.apiManager = apiManager
    }
    #endif

    // Public info about photobook products
    private(set) var products: [Photobook]?

    // List of all available layouts
    private(set) var layouts: [Layout]?
    
    // Current photobook
    var product: Photobook?
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    var productLayouts = [ProductLayout]()
    
    // TODO: Spine
    
    /// Requests the photobook details so the user can start building their photobook
    ///
    /// - Parameter completion: Completion block with an optional error
    func initialise(completion:@escaping (Error?)->()) {
        apiManager.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, error) in
            guard error != nil else {
                completion(error!)
                return
            }
            
            welf?.products = photobooks
            welf?.layouts = layouts
        }
    }
    
    func setPhotobook(_ photobook: Photobook, withAssets assets: [Asset]) {
        guard
            let coverLayouts = coverLayouts(for: photobook),
            coverLayouts.count > 0,
            let layouts = layouts(for: photobook),
            layouts.count > 0
        else {
            print("ProductManager: Missing layouts for selected photobook")
            return
        }

        var unusedAssets = assets

        var portraitLayouts = layouts.filter { !$0.isLandscape() && !$0.isEmptyLayout() && !$0.isDoubleLayout }
        var landscapeLayouts = layouts.filter { $0.isLandscape() && !$0.isEmptyLayout() && !$0.isDoubleLayout }
        
        // First photobook
        // TODO: Number of pages 3 + 2 * i
        if product == nil {
            var tempLayouts = [ProductLayout]()

            var currentPortraitLayout = 0
            var currentLandscapeLayout = 0

            // Use first photo for the cover
            let productLayoutAsset = ProductLayoutAsset()
            productLayoutAsset.asset = unusedAssets.remove(at: 0)
            let productLayout = ProductLayout(layout: coverLayouts.first!, productLayoutAsset: productLayoutAsset)
            tempLayouts.append(productLayout)
            
            // Loop through the remaining assets
            for asset in unusedAssets {
                // FIXME: Logic TBC
                let productLayoutAsset = ProductLayoutAsset()
                productLayoutAsset.asset = asset

                var layout: Layout
                if asset.isLandscape {
                    layout = landscapeLayouts[currentLandscapeLayout]
                    currentLandscapeLayout = currentLandscapeLayout < landscapeLayouts.count - 1 ? currentLandscapeLayout + 1 : 0
                } else {
                    layout = portraitLayouts[currentPortraitLayout]
                    currentPortraitLayout = currentPortraitLayout < portraitLayouts.count - 1 ? currentPortraitLayout + 1 : 0
                }
                let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset)
                tempLayouts.append(productLayout)
            }
            
            productLayouts = tempLayouts
            product = photobook
            return
        }
        
        // Switching products
        for pageLayout in productLayouts {
            // Match layouts from the current product to the new one
            var newLayout = layouts.first { $0.category == pageLayout.layout.category }
            if newLayout == nil {
                // Should not happen but to be safe, pick the first layout
                newLayout = layouts.first!
            }
            pageLayout.layout = newLayout
        }
    }
    
    private func coverLayouts(for photobook: Photobook) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.coverLayouts.contains($0.id) }
    }
    
    private func layouts(for photobook: Photobook) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.layouts.contains($0.id) }
    }
    
    /// Sets one of the available layouts for a page number
    ///
    /// - Parameters:
    ///   - layout: The layout to use
    ///   - page: The page index in the photobook
    func setLayout(_ layout: Layout, forPage page: Int) {
        productLayouts[page].layout = layout
    }
    
    /// Sets an asset as the content of one of the containers of a page in the photobook
    ///
    /// - Parameters:
    ///   - asset: The image asset to use
    ///   - page: The page index in the photbook
    func setAsset(_ asset: Asset, forPage page: Int) {
        productLayouts[page].asset = asset
    }
    
    /// Sets copy as the content of one of the containers of a page in the photobook
    ///
    /// - Parameters:
    ///   - text: The copy to use
    ///   - page: The page index in the photbook
    func setText(_ text: String, forPage page: Int) {
        productLayouts[page].text = text
    }
}
