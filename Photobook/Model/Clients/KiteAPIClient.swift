//
//  KiteAPIClient.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import PayPalDynamicLoader
import Stripe

enum OrderSubmitStatus: String {
    case cancelled, error, paymentError, unknown, received, accepted, validated, processed
    
    static func fromApiString(_ string: String) -> OrderSubmitStatus? {
        return OrderSubmitStatus(rawValue: string.lowercased())
    }
}

class KiteAPIClient {
    
    var apiKey: String?
    
    /// The environment of the app, live vs test
    static var environment: Environment = .live
    
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
    
    func submitOrder(parameters: [String: Any], completionHandler: @escaping (_ orderId: String?, _ error: APIClientError?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderSubmission
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { response, error in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            let orderId = (response as? [String: Any])?["print_order_id"] as? String
            
            if let responseError = (response as? [String: Any])?["error"] as? [String: Any] {
                guard let message = responseError["message"] as? String,
                    let errorCodeString = responseError["code"] as? String,
                    let errorCode = Int(errorCodeString)
                    else {
                        completionHandler(nil, .parsing(details: "SubmitOrder: Missing error info"))
                        return                        
                }
                
                if errorCode == 20, let orderId = orderId {
                    // This is not actually an error, we can report success.
                    completionHandler(orderId, nil)
                    return
                }
                
                completionHandler(nil, .server(code: errorCode, message: message))
                return
            }
            
            if let orderId = orderId  {
                completionHandler(orderId, nil)
                return
            }
            
            completionHandler(nil, .generic)
        }
    }
    
    func checkOrderStatus(receipt: String, completionHandler: @escaping (_ status: OrderSubmitStatus, _ error: APIClientError?, _ receipt: String?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderStatus + receipt
        APIClient.shared.get(context: .kite, endpoint: endpoint, parameters: nil, headers: kiteHeaders) { (response, error) in
            guard error == nil else {
                completionHandler(.error, error, nil)
                return
            }
            
            guard let pollingData = response as? [String: AnyObject] else {
                completionHandler(.error, .parsing(details: "CheckOrderStatus: Could not parse root object"), nil)
                return
            }

            if let errorDictionary = pollingData["error"] as? [String: AnyObject] {
                guard let code = errorDictionary["code"] as? String else {
                    completionHandler(.error, .parsing(details: "CheckOrderStatus: Missing error code"), nil)
                    return
                }
                
                if code == "E20" { // The order was successful but with a different (previously sent) print order id
                    let receipt = errorDictionary["print_order_id"] as? String
                    completionHandler(.validated, nil, receipt)
                } else if code == "P11" { // Payment error
                    completionHandler(.paymentError, nil, nil)
                } else if let message = errorDictionary["message"] as? String {
                    completionHandler(.error, .server(code: 0, message: message), nil)
                } else {
                    completionHandler(.error, .generic, nil)
                }
                return
            }
            
            guard let statusString = pollingData["status"] as? String,
                  let status = OrderSubmitStatus.fromApiString(statusString)
                else {
                    completionHandler(.error, .generic, nil)
                    return
            }
            
            completionHandler(status, nil, nil)
        }
    }

    /// Loads template information for a given array of template IDs.
    func getTemplateInfo(for templateIds: [String], completionHandler: @escaping (_ shippingClasses: [String: [ShippingMethod]]?, _ error: APIClientError?) -> Void) {

        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let uniqueTemplatesIds = Set(templateIds)
        var templateIdString = ""
        for templateId in uniqueTemplatesIds {
            if templateId != uniqueTemplatesIds.first { templateIdString += "," }
            templateIdString += templateId
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.template + "/?template_id__in=\(templateIdString)&limit=\(uniqueTemplatesIds.count)"
        APIClient.shared.get(context: .kite, endpoint: endpoint, headers: kiteHeaders) { (response, error) in
            
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            //get objects for each product
            guard let jsonDict = response as? [String: Any],
                let objects = jsonDict["objects"] as? [[String: Any]],
                let paymentKeys = jsonDict["payment_keys"] as? [String: Any]
            else {
                completionHandler(nil, .parsing(details: "GetTemplateInfo: Could not parse root objects"))
                return
            }
            
            if let payPalDict = paymentKeys["paypal"] as? [String: Any],
                let publicKey = payPalDict["public_key"] as? String {
                switch KiteAPIClient.environment {
                case .test:
                    OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["sandbox" : publicKey])
                    OLPayPalWrapper.preconnect(withEnvironment: "sandbox") /*PayPalEnvironmentSandbox*/
                case .live:
                    OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["live" : publicKey])
                    OLPayPalWrapper.preconnect(withEnvironment: "live") /*PayPalEnvironmentProduction*/
                }
            }
            
            if let stripeDict = paymentKeys["stripe"] as? [String: Any],
                let publicKey = stripeDict["public_key"] as? String {
                Stripe.setDefaultPublishableKey(publicKey)
            }
            
            var objectShippingClasses = [String: [ShippingMethod]]()
            
            for object in objects {
                var shippingClasses = [ShippingMethod]()
                let country = Country.countryForCurrentLocale()
                
                guard let regionMappings = object["country_to_region_mapping"] as? [String: Any],
                    let region = regionMappings[country.codeAlpha3] as? String,
                    let shippingRegions = object["shipping_regions"] as? [String: Any],
                    let relevantShippingRegion = shippingRegions[region] as? [String: Any],
                    let shippingClassDictionaries = relevantShippingRegion["shipping_classes"] as? [[String: Any]],
                    let templateId = object["template_id"] as? String
                    else {
                        completionHandler(nil, .parsing(details: "GetTemplateInfo: Could not parse region mapping"))
                        return
                }
                
                for dictionary in shippingClassDictionaries {
                    guard let shippingClass = ShippingMethod.parse(dictionary: dictionary) else {
                        completionHandler(nil, .parsing(details: "GetTemplateInfo: Could not parse shipping class"))
                        return
                    }
                    shippingClasses.append(shippingClass)
                }
                
                if shippingClasses.count == 0 { // Inconsistent
                    completionHandler(nil, .parsing(details: "GetTemplateInfo: Zero shipping classes parsed"))
                    return
                }
                
                objectShippingClasses[templateId] = shippingClasses
            }
            
            completionHandler(objectShippingClasses, nil)
        }
    }
    
    func getCost(order: Order, completionHandler: @escaping (_ cost: Cost?, _ error: APIClientError?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        var parameters = [String: Any]()
        parameters["currency"] = OrderManager.shared.preferredCurrencyCode
        
        let countryCode = order.deliveryDetails?.address?.country.codeAlpha3 ?? Country.countryForCurrentLocale().codeAlpha3
        if let promoCode = order.promoCode {
            parameters["promo_code"] = promoCode
        }
        
        var lineItems = [[String: Any]]()
        for product in order.products {
            let variantId = product.upsoldTemplate?.templateId ?? product.template.templateId
            guard let options = product.upsoldOptions,
                let shippingClass = product.selectedShippingMethod?.id else {
                    completionHandler(nil, nil)
                    return
            }
            let productDictionary: [String: Any] = ["quantity": product.itemCount,
                                                    "template_id": variantId,
                                                    "country_code": countryCode,
                                                    "shipping_class": shippingClass,
                                                    "page_count": product.numberOfPages,
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
                completionHandler(nil, .parsing(details: "GetCost: Could not parse cost"))
                return
            }
            
            completionHandler(cost, nil)
        }
    }
}
