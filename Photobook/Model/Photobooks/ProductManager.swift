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
    
    func reset() {
        currentProduct = nil
        PhotobookProductBackupManager.shared.deleteBackup()
    }
    
    /// Requests the photobook details so the user can start building their photobook
    ///
    /// - Parameter completion: Completion block with an optional error
    func initialise(completion: ((ErrorMessage?) -> Void)?) {
        apiManager.requestPhotobookInfo { [weak welf = self] result in
            guard let stelf = welf else { return }
            switch result {
            case .success(let photobookInfo):
                stelf.products = photobookInfo.photobookTemplates
                stelf.layouts = photobookInfo.layouts
                
                completion?(nil)
            case .failure(let error):
                if case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                completion?(ErrorMessage(error))
            }
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
    
    func changedCurrentProduct(with assets: [Asset]) {
        let productBackup = PhotobookProductBackup()
        productBackup.product = currentProduct
        productBackup.assets = assets
        
        PhotobookProductBackupManager.shared.saveBackup(productBackup)
    }
}
