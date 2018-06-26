//
//  KiteAPIClient.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

enum OrderSubmitStatus: String {
    case cancelled, error, paymentError, unknown, received, accepted, validated, processed
    
    static func fromApiString(_ string: String) -> OrderSubmitStatus? {
        return OrderSubmitStatus(rawValue: string.lowercased())
    }
}

class KiteAPIClient {
    
    var apiKey: String?
    
    private static let apiVersion = "v4.0"
    private struct Endpoints {
        static let orderSubmission = "/print"
        static let orderStatus = "/order/"
        static let cost = "/price"
        static let template = "/template"
    }
    
    static let shared = KiteAPIClient()
    
    private var kiteHeaders: [String: String] {
        return [
            "Authorization": "ApiKey \(apiKey ?? ""):",
            "X-App-Bundle-Id": Bundle.main.bundleIdentifier ?? "",
            "X-App-Name": Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "",
            "X-App-Version": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            "X-Person-UUID": Analytics.shared.userDistinctId
        ]
    }
    
    func submitOrder(parameters: [String: Any], completionHandler: @escaping (_ orderId: String?, _ error: ErrorMessage?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderSubmission
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { response, error in
            guard error == nil else {
                completionHandler(nil, ErrorMessage(error))
                return
            }
            
            let orderId = (response as? [String: Any])?["print_order_id"] as? String
            
            if let responseError = (response as? [String: Any])?["error"] as? [String: Any] {
                guard let message = responseError["message"] as? String,
                    let errorCodeString = responseError["code"] as? String,
                    let errorCode = Int(errorCodeString)
                    else { completionHandler(nil, ErrorMessage(APIClientError.parsing)); return }
                
                if errorCode == 20, let orderId = orderId {
                    // This is not actually an error, we can report success.
                    completionHandler(orderId, nil)
                    return
                }
                
                completionHandler(nil, ErrorMessage(APIClientError.server(code: errorCode, message: message)))
                return
            }
            
            if let orderId = orderId  {
                completionHandler(orderId, nil)
                return
            }
            
            completionHandler(nil, ErrorMessage(.generic))
        }
    }
    
    func checkOrderStatus(receipt: String, completionHandler: @escaping (_ status: OrderSubmitStatus, _ error: ErrorMessage?, _ receipt: String?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderStatus + receipt
        APIClient.shared.get(context: .kite, endpoint: endpoint, parameters: nil, headers: kiteHeaders) { (response, error) in
            if let error = error as? APIClientError {
                completionHandler(.error, ErrorMessage(error), nil)
                return
            }
            
            guard let pollingData = response as? [String: AnyObject] else {
                completionHandler(.error, nil, nil)
                return
            }

            if let errorDictionary = pollingData["error"] as? [String: AnyObject] {
                guard let code = errorDictionary["code"] as? String else {
                    completionHandler(.error, nil, nil)
                    return
                }
                
                if code == "E20" { // The order was successful but with a different (previously sent) print order id
                    let receipt = errorDictionary["print_order_id"] as? String
                    completionHandler(.validated, nil, receipt)
                } else if code == "P11" { // Payment error
                    completionHandler(.paymentError, nil, nil)
                } else {
                    completionHandler(.error, nil, nil)
                }
                return
            }
            
            guard let statusString = pollingData["status"] as? String,
                  let status = OrderSubmitStatus.fromApiString(statusString)
                else {
                    completionHandler(.error, nil, nil)
                    return
            }
            
            completionHandler(status, nil, nil)
        }
    }

    /// Loads shipping classes for a given order. This is different to shipping methods which contain the cost. ShippingClass is for displaying and setting shipping method id's
    func getShippingMethods(order: Order, completionHandler: @escaping (_ shippingClasses: [[ShippingMethod]]?, _ error: Error?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        var templateIdString = ""
        for product in order.products {
            if product != order.products.first { templateIdString += "," }
            templateIdString += product.template.templateId
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.template + "/?template_id__in=" + templateIdString
        APIClient.shared.get(context: .kite, endpoint: endpoint, headers: kiteHeaders) { (response, error) in
            
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            //get objects for each product
            guard let jsonDict = response as? [String: Any],
                let objects = jsonDict["objects"] as? [[String: Any]],
                objects.count == order.products.count else {
                completionHandler(nil, APIClientError.parsing)
                return
            }
            
            var objectShippingClasses = [[ShippingMethod]]()
            
            for object in objects {
                var shippingClasses = [ShippingMethod]()
                let country = Country.countryForCurrentLocale()
                
                guard let regionMappings = object["country_to_region_mapping"] as? [String: Any],
                    let region = regionMappings[country.codeAlpha3] as? String,
                    let shippingRegions = object["shipping_regions"] as? [String: Any],
                    let relevantShippingRegion = shippingRegions[region] as? [String: Any],
                    let shippingClassDictionaries = relevantShippingRegion["shipping_classes"] as? [[String: Any]] else {
                        completionHandler(nil, APIClientError.parsing)
                        return
                }
                
                for dictionary in shippingClassDictionaries {
                    guard let shippingClass = ShippingMethod.parse(dictionary: dictionary) else {
                        completionHandler(nil, APIClientError.parsing)
                        return
                    }
                    shippingClasses.append(shippingClass)
                }
                
                if shippingClasses.count == 0 { //inconsistent
                    completionHandler(nil, APIClientError.parsing)
                    return
                }
                
                objectShippingClasses.append(shippingClasses)
            }
            
            completionHandler(objectShippingClasses, nil)
        }
    }
    
    func getCost(order: Order, completionHandler: @escaping (_ cost: Cost?, _ error: Error?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        var parameters = [String: Any]()
        parameters["currency"] = order.currencyCode
        
        let countryCode = order.deliveryDetails?.address?.country.codeAlpha3 ?? Country.countryForCurrentLocale().codeAlpha3
        if let promoCode = order.promoCode {
            parameters["promo_code"] = promoCode
        }
        
        var lineItems = [[String: Any]]()
        for (index, product) in order.products.enumerated() {
            let variantId = product.upsoldTemplate?.templateId ?? product.template.templateId
            guard let options = product.upsoldOptions,
                let shippingClass = order.selectedShippingMethods?[index].id else {
                    completionHandler(nil, nil)
                    return
            }
            let productDictionary: [String: Any] = ["quantity": product.itemCount,
                                                    "template_id": variantId,
                                                    "country_code": countryCode,
                                                    "shipping_class": shippingClass,
                                                    "pages": product.numberOfPages,
                                                    "options": options
            ]
            lineItems.append(productDictionary)
        }
        
        parameters["basket"] = lineItems
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.cost
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: self.kiteHeaders) { response, error in
            
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            guard let response = response as? [String: Any], let cost = Cost.parseDetails(dictionary: response) else {
                completionHandler(nil, APIClientError.parsing)
                return
            }
            
            completionHandler(cost, nil)
        }
    }
}
