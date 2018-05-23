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
    
    static let imageUploadIdentifierPrefix = "PhotobookAPIManager-AssetUploader-"
    private static var headers = ["Authorization": "ApiKey 57c832e42dfdda93d072c6a42c41fbcddf100805"]
    
    struct EndPoints {
        static let products = "/ios/get_initial_data"
        static let summary = "/ios/summary"
        static let applyUpsell = "/ios/upsell.apply"
        static let createPdf = "/ios/generate_photobook_pdf"
        static let imageUpload = "/upload/"
    }

    private var apiClient = APIClient.shared
    
    #if DEBUG
    convenience init(apiClient: APIClient) {
        self.init()
        self.apiClient = apiClient
    }
    #endif
    
    /// Requests the information about photobook products and layouts from the API
    ///
    /// - Parameter completionHandler: Closure to be called when the request completes
    func requestPhotobookInfo(_ completionHandler:@escaping ([PhotobookTemplate]?, [Layout]?, [UpsellOption]?, Error?) -> ()) {

        apiClient.get(context: .photobook, endpoint: EndPoints.products, parameters: nil, headers: PhotobookAPIManager.headers) { (jsonData, error) in
            
            if jsonData == nil, error != nil {
                completionHandler(nil, nil, nil, error!)
                return
            }
            
            guard
                let photobooksData = jsonData as? [String: AnyObject],
                let productsData = photobooksData["products"] as? [[String: AnyObject]],
                let layoutsData = photobooksData["layouts"] as? [[String: AnyObject]]
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
            
            completionHandler(tempPhotobooks, tempLayouts, nil, nil)
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
    
}
