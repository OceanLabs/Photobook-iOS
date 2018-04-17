//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation
import UIKit

protocol PhotobookAPIManagerDelegate: class {
    var product: Photobook? { get set }
    var productLayouts: [ProductLayout] { get set }
    var coverColor: ProductColor { get set }
    var pageColor: ProductColor { get set }

    func didFinishUploading(asset: Asset)
    func didFailUpload(_ error: Error)
    func didFinishUploadingPhotobook()
    func didFinishCreatingPdf(error: Error?)
}

enum PhotobookAPIError: Error {
    case missingPhotobookInfo
    case couldNotBuildCreationParameters
    case couldNotSaveTempImageData
}

class PhotobookAPIManager {
    
    let imageUploadIdentifierPrefix = "PhotobookAPIManager-AssetUploader-"
    
    private struct EndPoints {
        static let products = "/ios/initial-data/"
        static let summary = "/ios/summary"
        static let applyUpsell = "/ios/upsell.apply"
        static let createPdf = "/ios/generate_photobook_pdf"
        static let imageUpload = "/upload/"
    }
    
    private struct Storage {
        static let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private var apiClient = APIClient.shared
    
    var pendingUploads:Int {
        get {
            return UserDefaults.standard.integer(forKey: "ly.kite.sdk.photobookAPIManager.pendingUploads")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.photobookAPIManager.pendingUploads")
            UserDefaults.standard.synchronize()
        }
    }
    var totalUploads:Int {
        get {
            return UserDefaults.standard.integer(forKey: "ly.kite.sdk.photobookAPIManager.totalUploads")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.photobookAPIManager.totalUploads")
            UserDefaults.standard.synchronize()
        }
    }
    var isUploading:Bool {
        get {
            return UserDefaults.standard.bool(forKey: "ly.kite.sdk.photobookAPIManager.isUploading")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.photobookAPIManager.isUploading")
            UserDefaults.standard.synchronize()
        }
    }
    weak var delegate: PhotobookAPIManagerDelegate?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(imageUploadFinished(_:)), name: APIClient.backgroundSessionTaskFinished, object: nil)
    }
    
    #if DEBUG
    convenience init(apiClient: APIClient) {
        self.init()
        self.apiClient = apiClient
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Requests the information about photobook products and layouts from the API
    ///
    /// - Parameter completionHandler: Closure to be called when the request completes
    func requestPhotobookInfo(_ completionHandler:@escaping ([Photobook]?, [Layout]?, [UpsellOption]?, Error?) -> ()) {
        
        apiClient.get(context: .photobook, endpoint: EndPoints.products) { (jsonData, error) in
            
            // TEMP: Fake api response. Don't run for tests.
            var jsonData = jsonData
            if NSClassFromString("XCTest") == nil {
                jsonData = JSON.parse(file: "photobooks")
            } else {
                if error != nil {
                    completionHandler(nil, nil, nil, error!)
                    return
                }
            }
            
            guard
                let photobooksData = jsonData as? [String: AnyObject],
                let productsData = photobooksData["products"] as? [[String: AnyObject]],
                let layoutsData = photobooksData["layouts"] as? [[String: AnyObject]],
                let upsellData = photobooksData["upsellOptions"] as? [[String: AnyObject]]
            else {
                completionHandler(nil, nil, nil, APIClientError.parsing)
                return
            }
            
            // Parse layouts
            var tempLayouts = [Layout]()
            for layoutDictionary in layoutsData {
                if let layout = Layout.parse(layoutDictionary) {
                    tempLayouts.append(layout)
                }
            }
            
            if tempLayouts.isEmpty {
                print("PBAPIManager: parsing layouts failed")
                completionHandler(nil, nil, nil, APIClientError.parsing)
                return
            }
            
            // Parse photobook products
            var tempPhotobooks = [Photobook]()
            
            for photobookDictionary in productsData {
                if let photobook = Photobook.parse(photobookDictionary) {
                    tempPhotobooks.append(photobook)
                }
            }
            
            if tempPhotobooks.isEmpty {
                print("PBAPIManager: parsing photobook products failed")
                completionHandler(nil, nil, nil, APIClientError.parsing)
                return
            }
            
            // Parse photobook upsell options
            var tempUpsellOptions = [UpsellOption]()
            
            for upsellOptionDictionary in upsellData {
                if let upsellOption = UpsellOption(upsellOptionDictionary) {
                    tempUpsellOptions.append(upsellOption)
                }
            }

            completionHandler(tempPhotobooks, tempLayouts, tempUpsellOptions, nil)
        }
    }
    
    /// Creates a PDF representation of current photobook. Two PDFs for cover and pages are provided as a URL.
    /// Note that those get generated asynchronously on the server and when the server returns 200 the process might still fail, affecting the placement of orders using them
    ///
    /// - Parameter completionHandler: Closure to be called with PDF URLs if successful, or an error if it fails
    func createPhotobookPdf(completionHandler: @escaping (_ urls: [String]?, _ error: Error?) -> Void) {
        apiClient.post(context: .photobook, endpoint: "ios/generate_pdf", parameters: photobookPDFParameters()) { (response, error) in
            guard let response = response as? [String:Any], let coverUrl = response["coverUrl"] as? String, let insideUrl = response["insideUrl"] as? String else {
                completionHandler(nil, error)
                return
            }
            print(coverUrl)
            completionHandler([coverUrl, insideUrl], nil)
        }
    }
    
    /// Uploads the photobook images and the user's photobook choices
    /// The PhotobookAPIManager listens to notifications from the APIClient to track the status of the background uploads.
    ///
    /// - Parameter completionHandler: Closure to be called with a total upload count, if the process successfully starts, or an error if it fails
    func uploadPhotobook(_ completionHandler: (Int, Error?) -> Void) {
        if isUploading {
            completionHandler(0, nil) //don't start uploading if upload in progress
            return
        }
        
        guard delegate?.product != nil, let productLayouts = delegate?.productLayouts else {
            completionHandler(0, PhotobookAPIError.missingPhotobookInfo)
            return
        }
        
        // Set upload counts
        totalUploads = 0
        let processedAssets = uploadableAssets(withProductLayouts: productLayouts)
        totalUploads = processedAssets.count
        pendingUploads = totalUploads
        isUploading = true
        completionHandler(totalUploads, nil)
        
        // Upload images
        
        for asset in processedAssets {

            asset.imageData(progressHandler: nil, completionHandler: { [weak welf = self] data, fileExtension, error in
                guard error == nil, let data = data, fileExtension != .unsupported else {
                    welf?.delegate?.didFailUpload(PhotobookAPIError.missingPhotobookInfo)
                    return
                }
                
                if let fileUrl = welf?.saveDataToCachesDirectory(data: data, name: "\(asset.fileIdentifier).\(fileExtension)") {
                    welf?.apiClient.uploadImage(fileUrl, reference: self.imageUploadIdentifierPrefix + asset.identifier, context: .pig, endpoint: EndPoints.imageUpload)
                } else {
                    welf?.delegate?.didFailUpload(PhotobookAPIError.couldNotSaveTempImageData)
                }
            })
        }
    }
    
    @objc func imageUploadFinished(_ notification: Notification) {
        
        guard let dictionary = notification.userInfo as? [String: AnyObject] else {
            print("PBAPIManager: Task finished but could not cast user info")
            return
        }
        
        //check if this is a photobook api manager asset upload
        if let reference = dictionary["task_reference"] as? String, !reference.hasPrefix(imageUploadIdentifierPrefix) {
            //not intended for this class
            return
        }
        
        if let error = dictionary["error"] as? APIClientError {
            delegate?.didFailUpload(error)
            return
        }
        
        guard let reference = dictionary["task_reference"] as? String,
            let url = dictionary["full"] as? String else {
                
            delegate?.didFailUpload(APIClientError.parsing)
            return
        }
        let referenceId = reference.suffix(reference.count - imageUploadIdentifierPrefix.count)
        
        guard let productLayout = delegate?.productLayouts.first(where: { $0.asset != nil && $0.asset!.identifier == referenceId }) else {
            delegate?.didFailUpload(PhotobookAPIError.missingPhotobookInfo)
            return
        }

        // Store the URL string
        productLayout.asset!.uploadUrl = url
        
        handleFinishedUploadingAsset(asset: productLayout.asset!)
    }
    
    private func handleFinishedUploadingAsset(asset:Asset) {
        // Reduce the count
        pendingUploads -= 1
        // Notify delegate
        delegate?.didFinishUploading(asset: asset)
        if pendingUploads == 0 {
            // All uploads done. Submit details and inform delegate
            isUploading = false
            delegate?.didFinishUploadingPhotobook()
        }
    }
    
    func restoreUploads(_ completionHandler: (() -> Void)? = nil) {
        guard let productLayouts = delegate?.productLayouts else {
            delegate?.didFailUpload(PhotobookAPIError.missingPhotobookInfo)
            return
        }

        totalUploads = 0
        for layout in productLayouts {
            if layout.asset != nil { totalUploads += 1 }
        }
        APIClient.shared.recreateBackgroundSession()
    }
    
    func cancelUpload(_ completion: @escaping () -> Void) {
        if isUploading {
            apiClient.cancelBackgroundTasks {
                self.isUploading = false
                self.pendingUploads = 0
                self.totalUploads = 0
                completion()
            }
        } else {
            completion()
        }
    }
    
    private func uploadableAssets(withProductLayouts layouts:[ProductLayout]) -> [Asset] {
        var processedAssets = [Asset]()
        layoutLoop: for layout in layouts {
            if let asset = layout.asset {
                //check if the asset is already processed for upload in another layout
                for processedAsset in processedAssets {
                    if processedAsset == asset {
                        continue layoutLoop
                    }
                }
                
                //check if it isn't a retry
                if asset.uploadUrl == nil {
                    processedAssets.append(asset)
                }
            }
        }
        return processedAssets
    }
    
    private func photobookPDFParameters() -> [String: Any]? {
        
        guard let product = ProductManager.shared.product else {
            return nil
        }
        
        var photobook = [String: Any]()
        
        //Pages
        var pages = [[String: Any]]()
        for productLayout in ProductManager.shared.productLayouts {
            var page = [String: Any]()
            
            var layoutBoxes = [[String:Any]]()
            
            if let asset = productLayout.asset,
                let imageLayoutBox = productLayout.layout.imageLayoutBox,
                let productLayoutAsset = productLayout.productLayoutAsset {
                
                var layoutBox = [String:Any]()
                
                productLayoutAsset.containerSize = imageLayoutBox.rectContained(in: CGSize(width: product.pageWidth, height: product.pageHeight)).size
                productLayoutAsset.adjustTransform()
                
                layoutBox["contentType"] = "image"
                layoutBox["isDoubleLayout"] = productLayout.layout.isDoubleLayout
                layoutBox["dimensionsPercentages"] = ["height": imageLayoutBox.rect.height, "width": imageLayoutBox.rect.width]
                layoutBox["relativeStartPoint"] = ["x": imageLayoutBox.rect.origin.x, "y": imageLayoutBox.rect.origin.y]
                
                // Set the container size to 1,1 so that the transform is relativized
                //productLayoutAsset.containerSize = CGSize(width: 1, height: 1)
                //productLayoutAsset.adjustTransform()
                
                var containedItem = [String: Any]()
                var picture = [String: Any]()
                picture["url"] = asset.uploadUrl
                picture["dimensions"] = ["height":asset.size.height, "width":asset.size.width]
                picture["thumbnailUrl"] = asset.uploadUrl //mock data
                containedItem["picture"] = picture
                containedItem["relativeStartPoint"] = ["x": productLayoutAsset.transform.tx, "y": productLayoutAsset.transform.ty]
                containedItem["rotation"] = atan2(productLayoutAsset.transform.b, productLayoutAsset.transform.a)
                
                var fillRatio = productLayoutAsset.containerSize.width / asset.size.width
                if asset.size.height < asset.size.width {
                    fillRatio = productLayoutAsset.containerSize.height / asset.size.height
                }
                let zoom = productLayoutAsset.transform.a - fillRatio
                print("Transform.a = \(productLayoutAsset.transform.a), Fill Ratio = \(fillRatio), zoom level: \(zoom)")
                containedItem["zoom"] = 1//1 + fillRatio - productLayoutAsset.transform.a // X & Y axes scale should be the same, use the scale for X axis
                containedItem["baseWidthPercent"] = 1 //mock data
                containedItem["flipped"] = false //mock data
                
                layoutBox["containedItem"] = containedItem
                
                layoutBoxes.append(layoutBox)
            }
            
            page["layoutBoxes"] = layoutBoxes
            pages.append(page)
        }
    
        photobook["pages"] = pages
        
        //product
        
        var productVariant = [String:Any]()
        
        productVariant["id"] = product.id
        productVariant["name"] = product.name
        productVariant["templateId"] = product.productTemplateId
        productVariant["pageWidth"] = product.pageWidth*2
        productVariant["pageHeight"] = product.pageHeight
        //TODO: replace mock data
        productVariant["cost"] = ["EUR":"25.00", "USD":"30.00", "GBP":"23.00"]
        productVariant["costPerPage"] = ["EUR":"1.30", "USD":"1.50", "GBP":"1.00"]
        productVariant["description"] = "description"
        productVariant["finishTypes"] = [["name":"gloss", "cost":["EUR":"1.30", "USD":"1.50", "GBP":"1.00"]]]
        productVariant["minPages"] = 20
        productVariant["maxPages"] = 70
        productVariant["coverSize"] = ["mm":["width":product.pageWidth, "height":product.pageHeight]]
        productVariant["size"] = ["mm":["width":product.pageWidth*2, "height":product.pageHeight]] //TODO: handle double size on backend // ["mm":["width":300, "height":300]]
        productVariant["pageStep"] = 0
        //productVariant["bleed"] = ["px":ProductManager.shared.bleed(forPageSize: CGSize(width: product.pageWidth, height: product.pageHeight)), "mm":ProductManager.shared.bleed(forPageSize: CGSize(width: product.pageWidth, height: product.pageHeight))]
        productVariant["bleed"] = ["px":0, "mm":0]
        productVariant["spine"] = ["ranges": ["20-38": 0,
                                              "40-54": 0,
                                              "56-70": 0,
                                              "72-88": 0,
                                              "90-104": 0,
                                              "106-120": 0,
                                              "122-134": 0,
                                              "136-140": 0], "multiplier":1] //mock data end
        
        photobook["productVariant"] = productVariant
        
        //config
        
        var photobookConfig = [String:Any]()
        
        photobookConfig["coverColor"] = ProductManager.shared.coverColor.uiColor().hex
        photobookConfig["pageColor"] = ProductManager.shared.pageColor.uiColor().hex
        
        var spineText = [String:Any]()
        
        spineText["text"] = ProductManager.shared.spineText
        spineText["color"] = ProductManager.shared.spineColor.hex
        
        var font = [String:Any]()
        
        font["fontFamily"] = ProductManager.shared.spineFontType.fontFamily
        //TODO: replace mock data
        font["fontSize"] = "20dp"
        font["fontSizePx"] = 20
        font["fontWeight"] = 1
        font["lineHeight"] = 20
        font["name"] = "name" //mock data end
        
        spineText["font"] = font
        
        photobookConfig["spineText"] = spineText
        
        photobook["photobookConfig"] = photobookConfig
        
        
        return photobook
    }
    
    private func saveDataToCachesDirectory(data: Data, name: String) -> URL? {
        let fileUrl = Storage.cachesDirectory.appendingPathComponent(name)
        do {
            try data.write(to: fileUrl)
            return fileUrl
        } catch {
            print(error)
            return nil
        }
    }
}
