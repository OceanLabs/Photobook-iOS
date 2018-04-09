//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

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
struct PhotobookBackup: Codable {
    var product: Photobook
    var coverColor: ProductColor
    var pageColor: ProductColor
    var productLayouts: [ProductLayout]
}

/// Manages the user's photobook; Storing, retrieving and uploading when necessary
class ProductManager {

    // Notification keys
    static let pendingUploadStatusUpdated = Notification.Name("ly.kite.sdk.productManagerPendingUploadStatusUpdated")
    static let shouldRetryUploadingImages = Notification.Name("ly.kite.sdk.productManagerShouldRetryUploadingImages")
    static let finishedPhotobookCreation = Notification.Name("ly.kite.sdk.productManagerFinishedPhotobookCreation")
    static let finishedPhotobookUpload = Notification.Name("ly.kite.sdk.productManagerFinishedPhotobookUpload")
    static let failedPhotobookUpload = Notification.Name("ly.kite.sdk.productManagerFailedPhotobookUpload")
    
    private let bleed: CGFloat = 8.5

    var currentPortraitLayout = 0
    var currentLandscapeLayout = 0
    
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
    
    var storageFile: String { return OrderManager.Storage.photobookBackupFile }
    #endif

    // Public info about photobook products
    private(set) var products: [Photobook]?

    // List of all available layouts
    private(set) var layouts: [Layout]?
    
    // List of all available upsell options
    private(set) var upsellOptions: [UpsellOption]?
    
    // Current photobook
    var product: Photobook?
    var productUpsellOptions: [UpsellOption]? //TODO: Get this from the initial-data endpoint
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
        return minimumRequiredAssets < productLayouts.count - 1 // Don't include cover for min calculation
    }
    var hasLayoutWithoutAsset: Bool {
        return productLayouts.first { $0.hasEmptyContent } != nil
    }
    var emptyLayoutIndices: [Int] {
        var temp = [Int]()
        var index = 0
        for productLayout in productLayouts {
            if productLayout.hasEmptyContent {
                temp.append(index)
                if productLayout.layout.isDoubleLayout {
                    index += 1
                    temp.append(index)
                }
            }
            index += 1
        }
        return temp
    }
    
    //upload
    var isUploading:Bool {
        get {
            return apiManager.isUploading
        }
        set {
            apiManager.isUploading = newValue
        }
    }
    var pendingUploads:Int {
        return apiManager.pendingUploads
    }
    var totalUploads:Int {
        return apiManager.totalUploads
    }
    
    func reset() {
        productLayouts = [ProductLayout]()
        product = nil
        spineText = nil
        coverColor = .white
        pageColor = .white
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

        let addedAssets = assets ?? {
            var assets = [Asset]()
            for layout in ProductManager.shared.productLayouts {
                guard let asset = layout.asset else { continue }
                assets.append(asset)
            }
            return assets
        }()
        
        let imageOnlyLayouts = layouts.filter({ $0.imageLayoutBox != nil })
        
        // First photobook only
        if product == nil {
            var tempLayouts = [ProductLayout]()

            // Use a random photo for the cover, but not the first
            let productLayoutAsset = ProductLayoutAsset()
            var coverAsset = addedAssets.first
            if addedAssets.count > 1 {
                coverAsset = addedAssets[(Int(arc4random()) % (addedAssets.count - 1)) + 1] // Exclude 0
            }
            productLayoutAsset.asset = coverAsset
            let coverLayout = coverLayouts.first(where: { $0.imageLayoutBox != nil } )
            let productLayout = ProductLayout(layout: coverLayout!, productLayoutAsset: productLayoutAsset)
            tempLayouts.append(productLayout)
            
            // Create layouts for the remaining assets
            tempLayouts.append(contentsOf: createLayoutsForAssets(assets: addedAssets, from: imageOnlyLayouts))
            
            // Fill minimum pages with Placeholder assets if needed
            let numberOfPlaceholderLayoutsNeeded = max(photobook.minimumRequiredAssets - tempLayouts.count, 0)            
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
        let doubleLayout = layouts.first { $0.isDoubleLayout }
    
        var productLayouts = [ProductLayout]()
        
        func nextLandscapeLayout() -> Layout {
            defer { currentLandscapeLayout = currentLandscapeLayout < landscapeLayouts.count - 1 ? currentLandscapeLayout + 1 : 0 }
            return landscapeLayouts[currentLandscapeLayout]
        }

        func nextPortraitLayout() -> Layout {
            defer { currentPortraitLayout = currentPortraitLayout < portraitLayouts.count - 1 ? currentPortraitLayout + 1 : 0 }
            return portraitLayouts[currentPortraitLayout]
        }

        // If assets count is an odd number, use a double layout close to the middle of the photobook
        var doubleAssetIndex: Int?
        if doubleLayout != nil, placeholderLayouts == 0 && assets.count % 2 != 0 {
            let middleIndex = (assets.count / 2) + 1
            for i in stride(from: 0, to: middleIndex-1, by: 2) { // Exclude first and last assets
                if assets[middleIndex - i].isLandscape {
                    doubleAssetIndex = middleIndex - i
                    break
                }
                if assets[middleIndex + i].isLandscape {
                    doubleAssetIndex = middleIndex + i
                    break
                }
            }
            doubleAssetIndex = doubleAssetIndex ?? middleIndex // Use middle index even though it is a portrait photo
        }

        for (index, asset) in assets.enumerated() {
            let productLayoutAsset = ProductLayoutAsset()
            productLayoutAsset.asset = asset
            
            let layout: Layout
            if let doubleAssetIndex = doubleAssetIndex, index == doubleAssetIndex {
                layout = doubleLayout!
            } else if asset.isLandscape {
                layout = nextLandscapeLayout()
            } else {
                layout = nextPortraitLayout()
            }
            let productLayoutText = layout.textLayoutBox != nil ? ProductLayoutText() : nil
            let productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: productLayoutText)
            productLayouts.append(productLayout)
        }
        
        var placeholderLayouts = placeholderLayouts
        while placeholderLayouts > 0 {
            let layout = placeholderLayouts % 2 == 0 ? nextLandscapeLayout() : nextPortraitLayout()
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
    func startPhotobookUpload(_ completionHandler: @escaping (Int, Error?) -> Void) {
        self.saveUserPhotobook()
        apiManager.uploadPhotobook(completionHandler)
    }
    
    func cancelPhotobookUpload(_ completionHandler: @escaping () -> Void) {
        apiManager.cancelUpload {
            completionHandler()
        }
    }
    
    /// Loads the user's photobook details from disk
    ///
    /// - Parameter completionHandler: Closure called on completion
    func loadUserPhotobook(_ completionHandler: (() -> Void)? = nil ) {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: OrderManager.Storage.photobookBackupFile) as? Data else {
            print("ProductManager: failed to unarchive product")
            return
        }
        guard let unarchivedProduct = try? PropertyListDecoder().decode(PhotobookBackup.self, from: unarchivedData) else {
            print("ProductManager: decoding of product failed")
            return
        }
        
        self.product = unarchivedProduct.product
        self.coverColor = unarchivedProduct.coverColor
        self.pageColor = unarchivedProduct.pageColor
        self.productLayouts = unarchivedProduct.productLayouts
        apiManager.restoreUploads()
        completionHandler?()
    }
    
    
    /// Saves the user's photobook details to disk
    func saveUserPhotobook() {
        guard let product = product else { return }
        
        let rootObject = PhotobookBackup(product: product, coverColor: coverColor, pageColor: pageColor, productLayouts: productLayouts)
        
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
    
    func spreadIndex(for productLayoutIndex: Int) -> Int? {
        var spreadIndex = 0.0
        
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
    
    func addPage(at index: Int) {
        addPages(at: index, number: 1)
    }
    
    func addDoubleSpread(at index: Int) {
        addPages(at: index, number: 2)
    }

    func addPages(at index: Int, pages: [ProductLayout]) {
        addPages(at: index, number: pages.count, pages: pages)
    }
    
    private func addPages(at index: Int, number: Int, pages: [ProductLayout]? = nil) {
        guard let product = product,
            let layouts = layouts(for: product)
            else { return }
        let newProductLayouts = pages ?? createLayoutsForAssets(assets: [], from: layouts, placeholderLayouts: number)
        
        productLayouts.insert(contentsOf: newProductLayouts, at: index)
    }
    
    func deletePage(at index: Int) {
        guard index < productLayouts.count else { return }
        productLayouts.remove(at: index)
    }
    
    func deletePages(for productLayout: ProductLayout) {
        guard let index = productLayouts.index(where: { $0 === productLayout }) else { return }
        productLayouts.remove(at: index)
        
        if !productLayout.layout.isDoubleLayout {
            productLayouts.remove(at: index)
        }
    }
    
    func pageType(forLayoutIndex index: Int) -> PageType {
        if index == 0 { return .cover }
        if index == 1 { return .first }
        if index == productLayouts.count - 1 { return .last }
        
        let doublePagesBeforeIndex = Array(productLayouts[0..<index]).filter { $0.layout.isDoubleLayout }.count
        
        if doublePagesBeforeIndex > 0 {
            return (index - doublePagesBeforeIndex) % 2 == 0 ? .left : .right
        }
        if index % 2 == 0 { return .left }
        return .right
    }
    
    func moveLayout(at sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < productLayouts.count && destinationIndex < productLayouts.count else { return }
        productLayouts.move(sourceIndex, to: destinationIndex)
    }
    
    func bleed(forPageSize size: CGSize) -> CGFloat {
        guard let product = product else { return 0.0 }
        let scaleFactor = size.height / product.pageHeight
        return bleed * scaleFactor
    }
    
    func createPhotobookPdf(completionHandler: @escaping (_ urls: [String]?, _ error: Error?) -> Void) {
        apiManager.createPhotobookPdf(completionHandler: completionHandler)
    }
}

extension ProductManager: PhotobookAPIManagerDelegate {

    func didFinishUploading(asset: Asset) {
        let info: [String: Any] = [ "asset": asset, "pending": apiManager.pendingUploads ]
        NotificationCenter.default.post(name: ProductManager.pendingUploadStatusUpdated, object: info)
        saveUserPhotobook()
    }
    
    func didFailUpload(_ error: Error) {
        if let error = error as? PhotobookAPIError {
            switch error {
            case .missingPhotobookInfo:
                NotificationCenter.default.post(name: ProductManager.failedPhotobookUpload, object: nil) //not resolvable
            case .couldNotSaveTempImageData:
                let info = [ "pending": apiManager.pendingUploads ]
                NotificationCenter.default.post(name: ProductManager.pendingUploadStatusUpdated, object: info)
                NotificationCenter.default.post(name: ProductManager.shouldRetryUploadingImages, object: nil) //resolvable
            case .couldNotBuildCreationParameters:
                NotificationCenter.default.post(name: ProductManager.failedPhotobookUpload, object: nil) //not resolvable
            }
        } else if let _ = error as? APIClientError {
            // Connection / server errors or parsing error
            NotificationCenter.default.post(name: ProductManager.shouldRetryUploadingImages, object: nil) //resolvable
        }
    }
    
    func didFinishUploadingPhotobook() {
        NotificationCenter.default.post(name: ProductManager.finishedPhotobookUpload, object: nil)
    }
    
    func didFinishCreatingPdf(error: Error?) {
        NotificationCenter.default.post(name: ProductManager.finishedPhotobookCreation, object: nil)
    }
}
