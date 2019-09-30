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

import Foundation

class PhotobookAPIManager {
    
    static var apiKey: String? {
        didSet {
            guard let apiKey = apiKey else { return }
            headers = ["Authorization": "ApiKey \(apiKey)"]
        }
    }
    
    private static var headers: [String: String]?
    
    struct EndPoints {
        static let products = "/ios/get_initial_data"
        static let summary = "/ios/get_summary"
        static let applyUpsells = "/ios/apply_upsells"
        static let createPdf = "/ios/generate_pdf"
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
    func requestPhotobookInfo(_ completionHandler: @escaping ((Result<(photobookTemplates: [PhotobookTemplate], layouts: [Layout]), APIClientError>) -> Void)) {

        apiClient.get(context: .photobook, endpoint: EndPoints.products, parameters: nil, headers: PhotobookAPIManager.headers) { result in
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let jsonData = try! result.get()
            
            guard
                let photobooksData = jsonData as? [String: AnyObject],
                let productsData = photobooksData["products"] as? [[String: AnyObject]],
                let layoutsData = photobooksData["layouts"] as? [[String: AnyObject]]
            else {
                completionHandler(.failure(.parsing(details: "RequestPhotobookInfo: Could not parse root objects")))
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
                completionHandler(.failure(.parsing(details: "RequestPhotobookInfo: Could not parse layouts")))
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
                completionHandler(.failure(.parsing(details: "RequestPhotobookInfo: Could not parse photobooks")))
                return
            }

            // Sort products by cover width
            tempPhotobooks.sort(by: { return $0.coverSize.width < $1.coverSize.width })
            
            completionHandler(.success((tempPhotobooks, tempLayouts)))
        }
    }
    
    func getOrderSummary(product: PhotobookProduct, completionHandler: @escaping (Result<(orderSummary: OrderSummary, upsellOptions: [UpsellOption], productPayload: [String: Any]), APIClientError>) -> Void) {
        
        let parameters: [String: Any] = ["productId": product.photobookTemplate.id, "pageCount": product.numberOfPages, "color": product.coverColor.rawValue, "currencyCode": OrderManager.shared.preferredCurrencyCode]
        apiClient.post(context: .photobook, endpoint: EndPoints.summary, parameters: parameters, headers: PhotobookAPIManager.headers) { result in
            
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()
            
            guard let jsonData = response as? [String: Any],
                let summaryDict = jsonData["summary"] as? [String: Any],
                let summary = OrderSummary.parse(summaryDict),
                let upsellOptionsDict = jsonData["upsells"] as? [[String: Any]],
                let payload = jsonData["productPayload"] as? [String: Any]
                else {
                    completionHandler(.failure(.parsing(details: "GetOrderSummary: Could not parse root objects")))
                    return
            }
            
            var upsellOptions = [UpsellOption]()
            for upsellDict in upsellOptionsDict {
                if let upsell = UpsellOption.parse(upsellDict) {
                    upsellOptions.append(upsell)
                }
            }
            
            completionHandler(.success((summary, upsellOptions, payload)))
        }
    }
    
    func applyUpsells(product: PhotobookProduct, upsellOptions:[UpsellOption], completionHandler: @escaping (Result<(summary: OrderSummary, upsoldTemplateId: String, productPayload: [String: Any]), APIClientError>) -> Void) {

        var parameters: [String: Any] = ["productId": product.photobookTemplate.id, "pageCount": product.numberOfPages, "color": product.coverColor.rawValue, "currencyCode": OrderManager.shared.preferredCurrencyCode]
        var upsellDicts = [[String: Any]]()
        for upsellOption in upsellOptions {
            upsellDicts.append(upsellOption.dict)
        }
        parameters["upsells"] = upsellDicts
        apiClient.post(context: .photobook, endpoint: EndPoints.applyUpsells, parameters: parameters, headers: PhotobookAPIManager.headers) { result in
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()

            guard let jsonData = response as? [String: Any],
                let summaryDict = jsonData["summary"] as? [String: Any],
                let summary = OrderSummary.parse(summaryDict),
                let productDict = jsonData["newProduct"] as? [String: Any],
                let variantDicts = productDict["variants"] as? [[String: Any]],
                let templateId = variantDicts.first?["templateId"] as? String,
                let payload = jsonData["productPayload"] as? [String: Any]
                else {
                    completionHandler(.failure(.parsing(details: "ApplyUpsells: Could not parse root objects")))
                    return
            }
        
            completionHandler(.success((summary, templateId, payload)))
        }
    }
    
    /// Creates a PDF representation of current photobook. Two PDFs for cover and pages are provided as a URL.
    /// Note that those get generated asynchronously on the server and when the server returns 200 the process might still fail, affecting the placement of orders using them
    ///
    /// - Parameters:
    ///   - photobook: Photobook product to use for creating the PDF
    ///   - completionHandler: Closure to be called with PDF URLs if successful, or an error if it fails
    func createPdf(withPhotobook photobook: PhotobookProduct, completionHandler: @escaping (Result<[String], APIClientError>) -> Void) {
        apiClient.post(context: .photobook, endpoint: EndPoints.createPdf, parameters: photobook.pdfParameters(), headers: PhotobookAPIManager.headers) { result in
            switch result {
            case .success(let response):
                if let response = response as? [String: Any], let coverUrl = response["coverUrl"] as? String, let insideUrl = response["insideUrl"] as? String {
                    completionHandler(.success([coverUrl, insideUrl]))
                    return
                }
                completionHandler(.failure(.generic))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
}
