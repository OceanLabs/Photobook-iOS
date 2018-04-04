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
            return UserDefaults.standard.integer(forKey: "ly.kite.sdk.PhotobookAPIManager.pendingUploads")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.PhotobookAPIManager.pendingUploads")
            UserDefaults.standard.synchronize()
        }
    }
    var totalUploads:Int {
        get {
            return UserDefaults.standard.integer(forKey: "ly.kite.sdk.PhotobookAPIManager.totalUploads")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.PhotobookAPIManager.totalUploads")
            UserDefaults.standard.synchronize()
        }
    }
    var isUploading:Bool {
        get {
            return UserDefaults.standard.bool(forKey: "ly.kite.sdk.PhotobookAPIManager.isUploading")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.PhotobookAPIManager.isUploading")
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
        completionHandler(["https://kite.ly/someurl", "https://kite.ly/someotherurl"], nil)
        //TODO: send request
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
                guard error == nil, let data = data, let fileExtension = fileExtension else {
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
            print("will cancel uploads")
            apiClient.cancelBackgroundTasks {
                self.isUploading = false
                self.pendingUploads = 0
                self.totalUploads = 0
                completion()
                print("did cancel uploads")
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
    
    private func photobookParameters() -> [String: Any]? {
        guard let photobookId = OrderManager.basketOrder.photobookId else { return nil }
        
        // TODO: confirm schema
        var photobook = [String: Any]()
        
        var pages = [[String: Any]]()
        for productLayout in ProductManager.shared.productLayouts {
            var page = [String: Any]()
            
            if let asset = productLayout.asset,
                let imageLayoutBox = productLayout.layout.imageLayoutBox,
                let productLayoutAsset = productLayout.productLayoutAsset {
                
                page["contentType"] = "image"
                page["dimensionsPercentages"] = ["height": imageLayoutBox.rect.height, "width": imageLayoutBox.rect.width]
                page["relativeStartPoint"] = ["x": imageLayoutBox.rect.origin.x, "y": imageLayoutBox.rect.origin.y]
                
                // Set the container size to 1,1 so that the transform is relativized
                productLayoutAsset.containerSize = CGSize(width: 1, height: 1)
                productLayoutAsset.adjustTransform()
                
                var containedItem = [String: Any]()
                var picture = [String: Any]()
                picture["url"] = asset.uploadUrl
                picture["relativeStartPoint"] = ["x": productLayoutAsset.transform.tx, "y": productLayoutAsset.transform.ty]
                picture["rotation"] = atan2(productLayoutAsset.transform.b, productLayoutAsset.transform.a)
                picture["zoom"] = productLayoutAsset.transform.a // X & Y axes scale should be the same, use the scale for X axis
                
                containedItem["picture"] = picture
                page["containedItem"] = containedItem
                
            }
            pages.append(page)
        }
        photobook["pages"] = pages
        photobook["pdfId"] = photobookId
        
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
