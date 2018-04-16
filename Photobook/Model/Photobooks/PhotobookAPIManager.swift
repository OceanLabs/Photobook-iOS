//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

enum PhotobookAPIError: Error {
    case missingPhotobookInfo
    case couldNotBuildCreationParameters
    case couldNotSaveTempImageData
}

class PhotobookAPIManager {
    
    private struct Storage {
        static let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    static let imageUploadIdentifierPrefix = "PhotobookAPIManager-AssetUploader-"
    
    private struct EndPoints {
        static let products = "/ios/initial-data/"
        static let summary = "/ios/summary"
        static let applyUpsell = "/ios/upsell.apply"
        static let createPdf = "/ios/generate_photobook_pdf"
        static let imageUpload = "/upload/"
    }

    private var apiClient = APIClient.shared
    
    #if DEBUG
    private var mockJsonFileName: String?
    convenience init(apiClient: APIClient, mockJsonFileName: String?) {
        self.init()
        self.apiClient = apiClient
        self.mockJsonFileName = mockJsonFileName
    }
    #endif
    
    /// Requests the information about photobook products and layouts from the API
    ///
    /// - Parameter completionHandler: Closure to be called when the request completes
    func requestPhotobookInfo(_ completionHandler:@escaping ([PhotobookTemplate]?, [Layout]?, [UpsellOption]?, Error?) -> ()) {
        
        apiClient.get(context: .photobook, endpoint: EndPoints.products) { (jsonData, error) in
            
            // TEMP: Fake api response. Don't run for tests.
            var jsonData = jsonData
            if NSClassFromString("XCTest") == nil {
                jsonData = JSON.parse(file: "photobooks")
            } else {
                #if DEBUG
                if let mockJsonFileName = self.mockJsonFileName {
                    jsonData = JSON.parse(file: mockJsonFileName)
                }
                #endif
                if jsonData == nil, error != nil {
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
                print("PhotobookAPIManager: parsing layouts failed")
                completionHandler(nil, nil, nil, APIClientError.parsing)
                return
            }
            
            // Parse photobook products
            var tempPhotobooks = [PhotobookTemplate]()
            
            for photobookDictionary in productsData {
                if let photobook = PhotobookTemplate.parse(photobookDictionary) {
                    tempPhotobooks.append(photobook)
                }
            }
            
            if tempPhotobooks.isEmpty {
                print("PhotobookAPIManager: parsing photobook products failed")
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
    
    func uploadAsset(asset: Asset, failureHandler: @escaping (Error) -> Void) {
        asset.imageData(progressHandler: nil, completionHandler: { [weak welf = self] data, fileExtension, error in
            guard error == nil, let data = data, fileExtension != .unsupported else {
                failureHandler(PhotobookAPIError.missingPhotobookInfo)
                return
            }
            
            if let fileUrl = welf?.saveDataToCachesDirectory(data: data, name: "\(asset.fileIdentifier).\(fileExtension)") {
                welf?.apiClient.uploadImage(fileUrl, reference: PhotobookAPIManager.imageUploadIdentifierPrefix + asset.identifier, context: .pig, endpoint: EndPoints.imageUpload)
            } else {
                failureHandler(PhotobookAPIError.couldNotSaveTempImageData)
            }
        })
    }
    
    func saveDataToCachesDirectory(data: Data, name: String) -> URL? {
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
