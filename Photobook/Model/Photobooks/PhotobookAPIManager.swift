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
    func didFinishCreatingPdf(error: Error?)
}

enum PhotobookAPIError: Error {
    case missingPhotobookInfo
    case couldNotBuildCreationParameters
    case couldNotSaveTempImage
}

class PhotobookAPIManager {
    
    let imageUploadIdentifierPrefix = "PhotobookAPIManager-AssetUploader-"
    
    private struct EndPoints {
        static let products = "/products/"
        static let imageUpload = "/upload/"
        static let pdfCreation = "" //TBC
    }
    
    private struct Storage {
        static let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private var apiClient = APIClient.shared
    
    var pendingUploads = 0
    var totalUploads = 0
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
        
        apiClient.get(context: .photobook, endpoint: EndPoints.products, parameters: nil) { (jsonData, error) in
            
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
            
            if tempLayouts.count == 0 {
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
            
            if tempPhotobooks.count == 0 {
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
    
    /// Uploads the photobook images and the user's photobook choices
    /// The PhotobookAPIManager listens to notifications from the APIClient to track the status of the background uploads.
    ///
    /// - Parameter completionHandler: Closure to be called with a total upload count, if the process successfully starts, or an error if it fails
    func uploadPhotobook(_ completionHandler: (Int, Error?) -> Void) {
        guard delegate?.product != nil, let productLayouts = delegate?.productLayouts else {
            completionHandler(0, PhotobookAPIError.missingPhotobookInfo)
            return
        }
        
        // Set upload counts
        for layout in productLayouts {
            if layout.asset != nil { totalUploads += 1 }
        }
        pendingUploads = totalUploads
        completionHandler(totalUploads, nil)
        
        // Upload images
        for layout in productLayouts {
            // Some layouts don't have assets
            guard let asset = layout.asset else { continue }
            
            // This might be a retry.
            guard asset.uploadUrl == nil else {
                delegate?.didFinishUploading(asset: asset)
                continue
            }

            // TEMP: Size doesn't seem necessary. Apply edits server side. Progress not needed either.
            asset.image(size: CGSize(width: Int.max, height: Int.max), applyEdits: false, progressHandler: nil, completionHandler: { [weak welf = self] (image, error) in
                if error != nil || image == nil {
                    welf?.delegate?.didFailUpload(PhotobookAPIError.couldNotSaveTempImage)
                    return
                }
                
                if let fileUrl = welf?.saveImageToCache(image: image!, name: "\(asset.identifier).jpg") {
                    welf?.apiClient.uploadImage(fileUrl, reference: self.imageUploadIdentifierPrefix + asset.identifier, context: .pig, endpoint: EndPoints.imageUpload)
                } else {
                    welf?.delegate?.didFailUpload(PhotobookAPIError.couldNotSaveTempImage)
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
        
        guard let productLayouts = delegate?.productLayouts else {
            fatalError("PBAPIManager: Layouts not available")
        }
        
        if let error = dictionary["error"] as? APIClientError {
            delegate?.didFailUpload(error)
        }
            
        guard let reference = dictionary["task_reference"] as? String,
            let url = dictionary["full"] as? String else {
                
            delegate?.didFailUpload(APIClientError.parsing)
            return
        }
        let referenceId = reference.suffix(reference.count - imageUploadIdentifierPrefix.count)
        
        guard let productLayout = productLayouts.first(where: { $0.asset != nil && $0.asset!.identifier == referenceId }) else {
            delegate?.didFailUpload(PhotobookAPIError.missingPhotobookInfo)
            return
        }

        // Store the URL string
        productLayout.asset!.uploadUrl = url
        
        // Notify delegate
        delegate?.didFinishUploading(asset: productLayout.asset!)

        // Reduce the count
        pendingUploads -= 1
        if pendingUploads == 0 {
            // All uploads done. Submit details and inform delegate
            submitPhotobookDetails() { [weak welf = self] (error) in
                welf?.delegate?.didFinishCreatingPdf(error: error)
            }
        }
    }
    
    func restoreUploads(_ completionHandler: @escaping () -> Void) {
        guard let productLayouts = delegate?.productLayouts else {
            delegate?.didFailUpload(PhotobookAPIError.missingPhotobookInfo)
            return
        }

        for layout in productLayouts {
            if layout.asset != nil { totalUploads += 1 }
        }
        APIClient.shared.recreateBackgroundSession(completionHandler)
    }
    

    // MARK: Private methods
    private func submitPhotobookDetails(_ completionHandler: @escaping (Error?) -> Void) {
        guard let parameters = photobookCreationParameters() else {
            completionHandler(PhotobookAPIError.couldNotBuildCreationParameters)
            return
        }
        
        apiClient.post(context: .pig, endpoint: EndPoints.pdfCreation, parameters: parameters) { ( jsonData, error) in
            completionHandler(error)
        }
    }
    
    private func photobookCreationParameters() -> [String: Any]? {
        // TODO: confirm schema
        return nil
    }
    
    private func saveImageToCache(image: UIImage, name: String) -> URL? {
        let fileUrl = Storage.cachesDirectory.appendingPathComponent(name)
        let data = UIImageJPEGRepresentation(image, 0.8)!
        do {
            try data.write(to: fileUrl)
            return fileUrl
        } catch {
            return nil
        }
    }
}
