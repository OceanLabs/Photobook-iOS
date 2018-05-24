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
    case productUnavailable
}

class PhotobookAPIManager {
    
    static let imageUploadIdentifierPrefix = "PhotobookAPIManager-AssetUploader-"
    
    struct EndPoints {
        static let products = "/ios/initial-data"
        static let summary = "/ios/get_summary"
        static let applyUpsells = "/ios/apply_upsells"
        static let createPdf = "/ios/generate_photobook_pdf"
        static let imageUpload = "/upload/"
    }

    private var apiClient = APIClient.shared
    
    private var mockJsonFileName: String?
    
    #if DEBUG
    convenience init(apiClient: APIClient, mockJsonFileName: String?) {
        self.init()
        self.apiClient = apiClient
        self.mockJsonFileName = mockJsonFileName
    }
    #endif
    
    private func authorizationHeader() -> [String: String]? {
        guard let apiKey = KiteAPIClient.shared.apiKey else {
            return nil
        }
        return ["Authorization": "ApiKey \(apiKey)"]
    }
    
    /// Requests the information about photobook products and layouts from the API
    ///
    /// - Parameter completionHandler: Closure to be called when the request completes
    func requestPhotobookInfo(_ completionHandler:@escaping ([PhotobookTemplate]?, [Layout]?, Error?) -> ()) {
        
        apiClient.get(context: .photobook, endpoint: EndPoints.products) { (jsonData, error) in
            
            // TEMP: Fake api response. Don't run for tests.
            var jsonData = jsonData
            if NSClassFromString("XCTest") == nil {
                jsonData = JSON.parse(file: "photobooks")
            } else {
                if let mockJsonFileName = self.mockJsonFileName {
                    jsonData = JSON.parse(file: mockJsonFileName)
                }
                if jsonData == nil, error != nil {
                    completionHandler(nil, nil, error!)
                    return
                }
            }
            
            guard
                let photobooksData = jsonData as? [String: AnyObject],
                let productsData = photobooksData["products"] as? [[String: AnyObject]],
                let layoutsData = photobooksData["layouts"] as? [[String: AnyObject]]
            else {
                completionHandler(nil, nil, APIClientError.parsing)
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
                completionHandler(nil, nil, APIClientError.parsing)
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
                completionHandler(nil, nil, APIClientError.parsing)
                return
            }

            completionHandler(tempPhotobooks, tempLayouts, nil)
        }
    }
    
    func getOrderSummary(product:PhotobookProduct, completionHandler: @escaping (_ summary: OrderSummary?, _ upsellOptions: [UpsellOption]?, _ productPayload: [String: Any]?, _ error: Error?) -> Void) {
        
        let parameters: [String: Any] = ["productId": product.template.id, "pageCount": product.productLayouts.count, "color": product.coverColor.rawValue]
        apiClient.post(context: .photobook, endpoint: EndPoints.summary, parameters: parameters, headers: authorizationHeader()) { (jsonData, error) in
            
            if let error = error {
                completionHandler(nil, nil, nil, error)
                return
            }
            
            guard let jsonData = jsonData as? [String: Any],
                let summaryDict = jsonData["summary"] as? [String: Any],
                let summary = OrderSummary.parse(summaryDict),
                let upsellOptionsDict = jsonData["upsells"] as? [[String: Any]],
                let payload = jsonData["productPayload"] as? [String: Any]
                else {
                completionHandler(nil, nil, nil, APIClientError.parsing)
                return
            }
            
            var upsellOptions = [UpsellOption]()
            for upsellDict in upsellOptionsDict {
                if let upsell = UpsellOption.parse(upsellDict) {
                    upsellOptions.append(upsell)
                }
            }
            
            completionHandler(summary, upsellOptions, payload, nil)
        }
    }
    
    func applyUpsells(product:PhotobookProduct, upsellOptions:[UpsellOption], completionHandler: @escaping (_ summary: OrderSummary?, _ upsoldTemplate: PhotobookTemplate?, _ productPayload: [String: Any]?, _ error: Error?) -> Void) {
        
        var parameters: [String: Any] = ["productId": product.template.id, "pageCount": product.productLayouts.count, "color": product.coverColor.rawValue]
        var upsellDicts = [[String: Any]]()
        for upsellOption in upsellOptions {
            upsellDicts.append(upsellOption.dict)
        }
        parameters["upsells"] = upsellDicts
        apiClient.post(context: .photobook, endpoint: EndPoints.applyUpsells, parameters: parameters, headers: authorizationHeader()) { (jsonData, error) in
            
            if let error = error {
                completionHandler(nil, nil, nil, error)
                return
            }
                                                                                        
            guard let jsonData = jsonData as? [String: Any],
                let summaryDict = jsonData["summary"] as? [String: Any],
                let summary = OrderSummary.parse(summaryDict),
                let productDict = jsonData["newProduct"] as? [String: Any],
                let variantDicts = productDict["variants"] as? [[String: Any]],
                let templateId = variantDicts.first?["templateId"] as? String,
                let payload = jsonData["productPayload"] as? [String: Any]
                else {
                    completionHandler(nil, nil, nil, APIClientError.parsing)
                    return
            }
            
            guard let template = ProductManager.shared.products?.first(where: {$0.productTemplateId == templateId}) else {
                //template of new product not available
                completionHandler(nil, nil, nil, PhotobookAPIError.productUnavailable)
                return
            }
        
            completionHandler(summary, template, payload, nil)
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
