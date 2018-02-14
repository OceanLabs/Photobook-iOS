//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Stripe

enum ProductColor: String, Codable {
    case white, black
    
    func fontColor() -> UIColor {
        switch self {
        case .white: return .black
        case .black: return .white
        }
    }
    
    func uiColor() -> UIColor {
        switch self {
        case .white: return .white
        case .black: return .black
        }
    }
}

// Structure containing the user's photobok details to save them to disk
struct PhotobookBackUp: Codable {
    var product: Photobook
    var coverColor: ProductColor
    var pageColor: ProductColor
    var productLayouts: [ProductLayout]
}

/// Manages the user's photobook; Storing, retrieving and uploading when necessary
class ProductManager {

    // Notification keys
    static let pendingUploadStatusUpdated = Notification.Name("ProductManagerPendingUploadStatusUpdated")
    static let shouldRetryUploadingImages = Notification.Name("ProductManagerShouldRetryUploadingImages")
    static let finishedPhotobookCreation = Notification.Name("ProductManagerFinishedPhotobookCreation")
    
    var currentPortraitLayout = 0
    var currentLandscapeLayout = 0
    
    private struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let photobookBackUpFile = photobookDirectory.appending("Photobook.dat")
    }
    
    static let shared: ProductManager = ProductManager()
    
    private lazy var apiManager: PhotobookAPIManager = {
        let manager = PhotobookAPIManager()
        manager.delegate = self
        return manager
    }()
    
    #if DEBUG
    convenience init(apiManager: PhotobookAPIManager) {
        self.init()
        self.apiManager = apiManager
    }
    
    var storageFile: String { return Storage.photobookBackUpFile }
    #endif

    // Public info about photobook products
    private(set) var products: [Photobook]?

    // List of all available layouts
    private(set) var layouts: [Layout]?
    
    // Current photobook
    var product: Photobook?
    var spineText: String?
    var spineFontType: FontType = .plain
    var coverColor: ProductColor = .white
    var pageColor: ProductColor = .white
    var productLayouts = [ProductLayout]()
    var minimumRequiredAssets: Int {
        let defaultMinimum = 20
        
        return product?.minimumRequiredAssets ?? products?.first?.minimumRequiredAssets ?? defaultMinimum
    }
    var maximumAllowedAssets: Int {
        // TODO: get this from the photobook
        return 70
    }
    var isAddingPagesAllowed: Bool {
        // TODO: Use pages count instead of assets/layout count
        return maximumAllowedAssets > productLayouts.count
    }
    var isRemovingPagesAllowed: Bool {
        // TODO: Use pages count instead of assets/layout count
        return minimumRequiredAssets < productLayouts.count
    }
    
    // Ordering (this should probably be in another class)
    var shippingMethod: Int?
    var currencyCode: String? = "GBP" // TODO: Get this from somewhere
    var deliveryDetails: DeliveryDetails?
    var paymentMethod: PaymentMethod? = Stripe.deviceSupportsApplePay() ? .applePay : nil
    var cachedCost: Cost? // private?
    var validCost: Cost? {
        return hasValidCachedCost ? cachedCost : nil
    }
    func updateCost(forceUpdate: Bool = false, _ completionHandler: @escaping (_ error : Error?) -> Void) {
        // TODO: update cost
        completionHandler(nil)
    }
    var hasValidCachedCost: Bool {
        // TODO: validate
//        return cachedCost?.orderHash == self.hashValue
        return true
    }
    var paymentToken: String?
    
    func reset() {
        productLayouts = [ProductLayout]()
        product = nil
        spineText = nil
        coverColor = .white
        pageColor = .white
    }
    
    
    // TODO: Spine
    
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
            
            // TODO: REMOVEME. Mock cost & shipping methods
            let lineItem = LineItem(id: 0, name: "Clown Costume 🤡", cost: Decimal(integerLiteral: 10), formattedCost: "$10")
            let shippingMethod = ShippingMethod(id: 1, name: "Fiesta Deliveries 🎉🚚", shippingCostFormatted: "$5", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$15", maxDeliveryTime: 150, minDeliveryTime: 100)
            let shippingMethod2 = ShippingMethod(id: 2, name: "Magic Unicorn ✨🦄✨", shippingCostFormatted: "$5000", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$5010", maxDeliveryTime: 1, minDeliveryTime: 0)
            self.cachedCost = Cost(hash: 0, lineItems: [lineItem], shippingMethods: [shippingMethod, shippingMethod2], promoDiscount: nil, promoCodeInvalidReason: nil)
        }
    }
    
    func setPhotobook(_ photobook: Photobook, withAssets assets: [Asset]? = nil) {
        guard
            let coverLayouts = coverLayouts(for: photobook),
            !coverLayouts.isEmpty,
            let layouts = layouts(for: photobook),
            !layouts.isEmpty
        else {
            print("ProductManager: Missing layouts for selected photobook")
            return
        }

        var addedAssets = assets ?? {
            var assets = [Asset]()
            for layout in ProductManager.shared.productLayouts{
                guard let asset = layout.asset else { continue }
                assets.append(asset)
            }
            return assets
        }()
        
        let imageOnlyLayouts = layouts.filter({ $0.imageLayoutBox != nil })
        
        // First photobook only
        if product == nil {
            var tempLayouts = [ProductLayout]()

            // Use first photo for the cover
            let productLayoutAsset = ProductLayoutAsset()
            productLayoutAsset.asset = addedAssets.remove(at: 0)
            let coverLayout = coverLayouts.first(where: { $0.imageLayoutBox != nil } )
            let productLayout = ProductLayout(layout: coverLayout!, productLayoutAsset: productLayoutAsset)
            tempLayouts.append(productLayout)
            
            // Create layouts for the remaining assets
            tempLayouts.append(contentsOf: createLayoutsForAssets(assets: addedAssets, from: imageOnlyLayouts))
            
            // Fill minimum pages with Placeholder assets if needed
            var numberOfPlaceholderLayoutsNeeded = max(photobook.minimumRequiredAssets - tempLayouts.count, 0)
            
            // We need an odd number of layouts including the cover and the 2 courtesy pages
            if tempLayouts.count % 2 == 0 {
                numberOfPlaceholderLayoutsNeeded += 1
            }
            tempLayouts.append(contentsOf: createLayoutsForAssets(assets: [], from: imageOnlyLayouts, placeholderLayouts: numberOfPlaceholderLayoutsNeeded))
            
            productLayouts = tempLayouts
            product = photobook
            return
        }
        
        // Reset the current layout since we are changing products
        currentLandscapeLayout = 0
        currentPortraitLayout = 0
        
        // Switching products
        product = photobook
        for pageLayout in productLayouts {
            let availableLayouts = pageLayout === productLayouts.first ? coverLayouts : layouts
            
            // Match layouts from the current product to the new one
            var newLayout = availableLayouts.first {
                $0.category == pageLayout.layout.category
            }
            if newLayout == nil {
                // Should not happen but to be safe, pick the first layout
                newLayout = availableLayouts.first
            }
            pageLayout.layout = newLayout
        }
    }
    
    func createLayoutsForAssets(assets: [Asset], from layouts:[Layout], placeholderLayouts: Int = 0) -> [ProductLayout] {
        var portraitLayouts = layouts.filter { !$0.isLandscape() && !$0.isEmptyLayout() && !$0.isDoubleLayout }
        var landscapeLayouts = layouts.filter { $0.isLandscape() && !$0.isEmptyLayout() && !$0.isDoubleLayout }
    
        var productLayouts = [ProductLayout]()
        
        for asset in assets {
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
            let productLayoutText = layout.textLayoutBox != nil ? ProductLayoutText() : nil
            let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: productLayoutText)
            productLayouts.append(productLayout)
        }
        
        var placeholderLayouts = placeholderLayouts
        while placeholderLayouts > 0 {
            let layout = landscapeLayouts[currentLandscapeLayout]
            currentLandscapeLayout = currentLandscapeLayout < landscapeLayouts.count - 1 ? currentLandscapeLayout + 1 : 0
            let productLayout = ProductLayout(layout: layout, productLayoutAsset: nil)
            productLayouts.append(productLayout)
            placeholderLayouts -= 1
        }
        
        return productLayouts
    }
    
    func coverLayouts(for photobook: Photobook) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.coverLayouts.contains($0.id) }
    }
    
    func layouts(for photobook: Photobook) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.layouts.contains($0.id) }
    }
    
    func currentCoverLayouts() -> [Layout]? {
        guard product != nil else { return nil }
        return coverLayouts(for: product!)
    }
    
    func currentLayouts() -> [Layout]? {
        guard product != nil else { return nil }
        return layouts(for: product!)
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
    
    /// Initiates the uploading of the user's photobook
    ///
    /// - Parameter completionHandler: Executed when the uploads are on the way or failed to initiate them. The Int parameter provides the total upload count.
    func startPhotobookUpload(_ completionHandler: (Int, Error?) -> Void) {
        self.saveUserPhotobook()
        apiManager.uploadPhotobook(completionHandler)
    }
    
    /// Loads the user's photobook details from disk
    ///
    /// - Parameter completionHandler: Closure called on completion
    func loadUserPhotobook(_ completionHandler: @escaping () -> Void) {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: Storage.photobookBackUpFile) as? Data else {
            print("ProductManager: failed to unarchive product")
            return
        }
        guard let unarchivedProduct = try? PropertyListDecoder().decode([String: Any].self, from: unarchivedData) else {
            print("ProductManager: decoding of product failed")
            return
        }
        
        if let product = unarchivedProduct["product"] as? Photobook,
           let coverColor = unarchivedProduct["coverColor"] as? ProductColor,
           let pageColor = unarchivedProduct["pageColor"] as? ProductColor,
           let productLayouts = unarchivedProduct["productLayouts"] as? [ProductLayout] {
                self.product = product
                self.coverColor = coverColor
                self.pageColor = pageColor
                self.productLayouts = productLayouts
        }
        apiManager.restoreUploads(completionHandler)
    }
    
    
    /// Saves the user's photobook details to disk
    func saveUserPhotobook() {
        guard let product = product else { return }
        
        let rootObject = PhotobookBackUp(product: product, coverColor: coverColor, pageColor: pageColor, productLayouts: productLayouts)
        
        guard let data = try? PropertyListEncoder().encode(rootObject) else {
            fatalError("ProductManager: encoding of product failed")
        }
        
        if !FileManager.default.fileExists(atPath: Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("ProductManager: could not save photobook")
            }
        }
        
        let saved = NSKeyedArchiver.archiveRootObject(data, toFile: Storage.photobookBackUpFile)
        if !saved {
            print("ProductManager: failed to archive product")
        }
    }
    
    func spreadIndex(for productLayoutIndex: Int) -> Int? {
        var spreadIndex = 0.5 // The first page is on the right because of the courtesy page
        
        var i = 0
        while i < productLayouts.count {
            if i == productLayoutIndex {
                return Int(spreadIndex)
            }
            
            spreadIndex += productLayouts[i].layout.isDoubleLayout ? 1 : 0.5
            i += 1
        }
        
        return nil
    }
    
    func productLayoutIndex(for spreadIndex: Int) -> Int? {
        var spreadIndexCount = 1 // Skip the first spread which includes the courtesy page
        var i = 2 // Skip the cover and the page on the first spread
        while i < productLayouts.count {
            if spreadIndex == spreadIndexCount {
                return i
            }
            i += productLayouts[i].layout.isDoubleLayout ? 1 : 2
            spreadIndexCount += 1
        }
        
        return nil
    }
    
    func addPages(at index: Int, pages: [ProductLayout]? = nil) {
        guard let product = product,
            let layouts = layouts(for: product)
            else { return }
        let newProductLayouts = pages ?? createLayoutsForAssets(assets: [], from: layouts, placeholderLayouts: 2)
        
        productLayouts.insert(contentsOf: newProductLayouts, at: index)
    }
    
    func deletePage(at productLayout: ProductLayout) {
        guard let index = productLayouts.index(where: { $0 === productLayout }) else { return }
        productLayouts.remove(at: index)
        
        if !productLayout.layout.isDoubleLayout {
            productLayouts.remove(at: index)
        }
    }
    
}

extension ProductManager: PhotobookAPIManagerDelegate {

    func didFinishUploading(asset: Asset) {
        let info: [String: Any] = [ "asset": asset, "pending": apiManager.pendingUploads ]
        NotificationCenter.default.post(name: ProductManager.pendingUploadStatusUpdated, object: info)
    }
    
    func didFailUpload(_ error: Error) {
        if let error = error as? PhotobookAPIError {
            switch error {
            case .missingPhotobookInfo:
                fatalError("ProductManager: incorrect or missing photobook info")
            case .couldNotSaveTempImage:
                let info = [ "pending": apiManager.pendingUploads ]
                NotificationCenter.default.post(name: ProductManager.pendingUploadStatusUpdated, object: info)
                
                NotificationCenter.default.post(name: ProductManager.shouldRetryUploadingImages, object: nil)
            case .couldNotBuildCreationParameters:
                fatalError("PhotobookManager: could not build PDF creation request parameters")
            }
        } else if let _ = error as? APIClientError {
            // Connection / server errors are handled by the system. This can only be a parsing error.
            fatalError("ProductManager: could not parse upload response")
        }
    }
    
    func didFinishCreatingPdf(error: Error?) {
        NotificationCenter.default.post(name: ProductManager.finishedPhotobookCreation, object: nil)
    }
}
