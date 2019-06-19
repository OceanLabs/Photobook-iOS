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

import UIKit
import Stripe
import KeychainSwift

enum OrderSubmitStatus: String {
    case cancelled, error, paymentError, unknown, received, accepted, validated, processed
    
    static func fromApiString(_ string: String) -> OrderSubmitStatus? {
        return OrderSubmitStatus(rawValue: string.lowercased())
    }
}

enum MimeType {
    case pdf, jpeg, gif
    func headerString() -> String {
        switch self {
        case .pdf: return "application/pdf"
        case .jpeg: return "image/jpeg"
        case .gif: return "image/gif"
        }
    }
}

struct KiteApiNotificationName {
    static let failedToCreateCustomerKey = Notification.Name("ly.kite.photobook.failedToCreateCustomerKeyNotificationName")
}

class KiteAPIClient: NSObject {
    
    var apiKey: String?
    lazy var urlScheme: String? = {
        guard let apiKey = apiKey else { return nil }
        return "kite\(apiKey)"
    }()
    
    /// The environment of the app, live vs test
    static var environment: Environment = .live
    
    private static let apiVersion = "v5"
    private static let sdkVersion = "v1.0.0"
    static let userAgent = "Kite SDK iOS Swift \(sdkVersion)"

    private struct Endpoints {
        static let orderSubmission = "/print"
        static let orderStatus = "/order/"
        static let cost = "/price"
        static let template = "/template"
        static let shipping = "/template/shipping"
        static let registrationRequest = "/asset/sign"
        static let ephemeralKey = "/create_ephemeral_key/"
        static let createStripeCustomer = "/create_stripe_customer/"
        static let createStripePaymentIntent = "/create_stripe_payment_intent/"
    }
    
    static let shared = KiteAPIClient()
    
    private var kiteHeaders: [String: String] {
        return [
            "Authorization": "ApiKey \(apiKey ?? ""):",
            "X-App-Bundle-Id": Bundle.main.bundleIdentifier ?? "",
            "X-App-Name": Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "",
            "X-App-Version": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            "X-Person-UUID": Analytics.shared.userDistinctId,
            "User-Agent": KiteAPIClient.userAgent
        ]
    }
    
    private var stripeCustomerId: String?
    
    func requestSignedUrl(for type: MimeType, _ completionHandler: @escaping ((_ signedUrl: URL?, _ fileUrl: URL?, _ error: APIClientError?) -> ())) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.registrationRequest
        let parameters = ["mime_types": type.headerString(),
                          "client_asset": "true"]
        APIClient.shared.get(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { response, error in
            guard error == nil else {
                completionHandler(nil, nil, error)
                return
            }

            guard let signedUrlStrings = (response as? [String: Any])?["signed_requests"],
                  let signedUrlString = (signedUrlStrings as? [String])?.first,
                  let signedUrl = URL(string: signedUrlString),
                  let fileUrlStrings = (response as? [String: Any])?["urls"],
                  let fileUrlString = (fileUrlStrings as? [String])?.first,
                  let fileUrl = URL(string: fileUrlString)
            else {
                completionHandler(nil, nil, APIClientError.parsing(details: "RequestSignedUrl: Could not parse signed requests"))
                return
            }
            return completionHandler(signedUrl, fileUrl, nil)
        }
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
            
            let orderId = (response as? [String: Any])?["order_id"] as? String
            
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

    /// Retrieve PalPal and Stripe keys
    func getPaymentKeys(completionHandler: @escaping (_ paypalKey: String?, _ stripeKey: String?, _ error: APIClientError?) -> Void) {
        
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.template + "/?limit=1"
        APIClient.shared.get(context: .kite, endpoint: endpoint, headers: kiteHeaders) { (response, error) in
            
            if let error = error {
                completionHandler(nil, nil, error)
                return
            }
            
            //get objects for each product
            guard let jsonDict = response as? [String: Any],
                  let paymentKeys = jsonDict["payment_keys"] as? [String: Any]
            else {
                completionHandler(nil, nil, .parsing(details: "GetTemplateInfo: Could not parse root objects"))
                return
            }
            
            var payPalKey: String?
            var stripeKey: String?
            if let payPalDict = paymentKeys["paypal"] as? [String: Any],
                let publicKey = payPalDict["public_key"] as? String {
                payPalKey = publicKey
            }
            
            if let stripeDict = paymentKeys["stripe"] as? [String: Any],
                let publicKey = stripeDict["public_key"] as? String {
                stripeKey = publicKey
            }

            completionHandler(payPalKey, stripeKey, nil)
        }
    }
    
    /// Loads shipping information for a given array of template IDs.
    func getShippingInfo(for templateIds: [String], completionHandler: @escaping (_ shippingInfo: [String: Any]?, _ error: APIClientError?) -> Void) {
        
        guard apiKey != nil else {
            fatalError("Missing Kite API key: KiteSDK.shared.kiteApiKey")
        }
        
        let uniqueTemplatesIds = Set(templateIds)
        var templateIdString = ""
        for templateId in uniqueTemplatesIds {
            if templateId != uniqueTemplatesIds.first { templateIdString += "," }
            templateIdString += templateId
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.shipping + "/?template_ids=\(templateIdString)"
        APIClient.shared.get(context: .kite, endpoint: endpoint, headers: kiteHeaders) { (response, error) in
            
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            //get objects for each product
            guard let jsonDict = response as? [String: Any],
                let objects = jsonDict["objects"] as? [String: Any]
                else {
                    completionHandler(nil, .parsing(details: "GetShippingInfo: Could not parse root objects"))
                    return
            }
            
            var shippingInfo = [String: Any]()
            for object in objects {
                let templateId = object.key
                guard let dict = object.value as? [String: Any]
                    else {
                        completionHandler(nil, .parsing(details: "GetShippingInfo: Could not parse region mapping. Missing object."))
                        return
                }
                
                var regionShippingClasses = [String: [ShippingMethod]]()
                
                guard let regionMappings = dict["country_to_region_mapping"] as? [String: [String]],
                    let shippingRegions = dict["shipping_regions"] as? [String: Any]
                    else {
                        completionHandler(nil, .parsing(details: "GetShippingInfo: Could not parse region mapping"))
                        return
                }
                
                for region in shippingRegions.keys {
                    var shippingClasses = [ShippingMethod]()
                    if let shippingClassesDictionaries = ((shippingRegions[region] as? [String: Any])?["shipping_classes"]) as? [[String: Any]] {
                        let orderedShippingClasses = shippingClassesDictionaries.sorted(by: {
                            $0["max_delivery_time"] as! Int > $1["max_delivery_time"] as! Int
                        })
                        
                        for dictionary in orderedShippingClasses {
                            guard let shippingClass = ShippingMethod.parse(dictionary: dictionary) else {
                                completionHandler(nil, .parsing(details: "GetShippingInfo: Could not parse shipping class"))
                                return
                            }
                            shippingClasses.append(shippingClass)
                        }
                    }
                    regionShippingClasses[region] = shippingClasses
                }
                
                if regionShippingClasses.keys.count == 0 { // Inconsistent
                    completionHandler(nil, .parsing(details: "GetShippingInfo: zero shipping classes parsed"))
                    return
                }
                
                shippingInfo[templateId] = ["availableShippingMethods": regionShippingClasses, "countryToRegionMapping": regionMappings]
            }
            
            if shippingInfo.isEmpty {
                completionHandler(nil, .parsing(details: "GetShippingInfo: No templates returned"))
                return
            }
            
            completionHandler(shippingInfo, nil)
        }
    }
    
    func getCost(order: Order, completionHandler: @escaping (_ cost: Cost?, _ error: APIClientError?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        var parameters = [String: Any]()
        parameters["currencies"] = [OrderManager.shared.preferredCurrencyCode]
        
        if let promoCode = order.promoCode {
            parameters["promo_code"] = promoCode
        }
        
        var lineItems = [[String: Any]]()
        for product in order.products {
            guard let parameters = product.costParameters() else {
                continue
            }
            lineItems.append(parameters)
        }
        
        parameters["shipping_address"] = ["country_code": order.deliveryDetails?.country.codeAlpha3 ?? Country.countryForCurrentLocale().codeAlpha3]
        parameters["jobs"] = lineItems

        let endpoint = KiteAPIClient.apiVersion + Endpoints.cost
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { response, error in
            
            guard error == nil else {
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
    
    // MARK: - Stripe
    func createStripeCustomer(_ completionHandler: @escaping (_ customerId: String?, _ error: APIClientError?) -> Void) {
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.createStripeCustomer
        APIClient.shared.post(context: .kite, endpoint: endpoint, headers: kiteHeaders) { response, error in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            guard let res = response as? [String: Any], let customerId = res["stripe_customer_id"] as? String else {
                completionHandler(nil, .parsing(details: "CreateStripeCustomer: Could not parse customer ID"))
                return
            }
            
            completionHandler(customerId, nil)
        }
    }
    
    func createPaymentIntentWithSourceId(_ sourceId: String, amount: Double, currency: String, completionHandler: @escaping (_ paymentIntent: STPPaymentIntent?, _ error: APIClientError?) -> Void)
    {
        guard let urlScheme = urlScheme else {
            fatalError("Invalid URL Scheme: API key is nil or a nil scheme was provided")
        }
        
        if stripeCustomerId == nil {
            stripeCustomerId = StripeCredentialsHandler.load()
        }
        
        guard let customerId = stripeCustomerId else {
            completionHandler(nil, .generic)
            return
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.createStripePaymentIntent
        let parameters: [String: Any] = ["stripe_customer_id": customerId,
                                         "source": sourceId,
                                         "amount": amount,
                                         "currency": currency,
                                         "return_url": "\(urlScheme)://stripe-redirect"]
        
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { response, error in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            guard let res = response as? [String: Any], let clientSecret = res["client_secret"] as? String else {
                completionHandler(nil, .parsing(details: "CreatePaymentIntent: could not parse client"))
                return
            }
            
            STPAPIClient.shared().retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, error in
                guard error == nil else {
                    completionHandler(nil, .parsing(details: "CreatePaymentIntent: could not retrieve payment details"))
                    return
                }
                
                completionHandler(paymentIntent, nil)
            }
        }
    }    
}

extension KiteAPIClient: STPCustomerEphemeralKeyProvider {
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        
        var parameters = ["api_version": apiVersion]
        
        func requestEphemeralKey(for customerId: String) {
            parameters["stripe_customer_id"] = customerId
            
            let endpoint = KiteAPIClient.apiVersion + Endpoints.ephemeralKey
            APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { response, error in
                guard error == nil else {
                    if case APIClientError.parsing(_) = error! {
                        // If there was a parsing error, chances are the customer ID is invalid
                        StripeCredentialsHandler.delete()
                        NotificationCenter.default.post(name: KiteApiNotificationName.failedToCreateCustomerKey, object: nil)
                    }
                    completion(nil, error)
                    return
                }
                completion(response as? [AnyHashable: Any], nil)
            }
        }
        
        if stripeCustomerId == nil {
            stripeCustomerId = StripeCredentialsHandler.load()
        }

        if let customerId = stripeCustomerId {
            requestEphemeralKey(for: customerId)
            return
        }

        createStripeCustomer { [weak welf = self] (customerId, error) in
            guard error == nil, let cusId = customerId else {
                completion(nil, error)
                return
            }

            welf?.stripeCustomerId = cusId
            StripeCredentialsHandler.save(cusId)
            requestEphemeralKey(for: cusId)
        }
    }
}


fileprivate class StripeCredentialsHandler {
    
    private struct StorageKeys {
        static var live = "StripeLiveCustomerIdKey"
        static var test = "StripeTestCustomerIdKey"
    }

    private static var storageKey: String {
        return APIClient.environment == .live ? StorageKeys.live : StorageKeys.test
    }
    
    static func save(_ key: String) {
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") { return }
        KeychainSwift().set(key, forKey: storageKey)
    }
    
    static func load() -> String? {
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") { return nil }
        return KeychainSwift().get(storageKey)
    }
    
    static func delete() {
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") { return }
        KeychainSwift().delete(storageKey)
    }
}
