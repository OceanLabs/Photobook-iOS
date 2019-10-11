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
    case cancelled, unknown, received, accepted, validated, processed
    
    static func fromApiString(_ string: String) -> OrderSubmitStatus? {
        return OrderSubmitStatus(rawValue: string.lowercased())
    }
}

enum KiteAPIClientError: Error {
    case paymentError
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
    var urlScheme: String?
    
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
    
    var stripeCustomerId: String?
    
    func requestSignedUrl(for type: MimeType, _ completionHandler: @escaping (Result<(signedUrl: URL, fileUrl: URL), APIClientError>) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.registrationRequest
        let parameters = ["mime_types": type.headerString(),
                          "client_asset": "true"]
        APIClient.shared.get(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { result in
            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let response):
                guard let signedUrlStrings = (response as? [String: Any])?["signed_requests"],
                      let signedUrlString = (signedUrlStrings as? [String])?.first,
                      let signedUrl = URL(string: signedUrlString),
                      let fileUrlStrings = (response as? [String: Any])?["urls"],
                      let fileUrlString = (fileUrlStrings as? [String])?.first,
                      let fileUrl = URL(string: fileUrlString)
                else {
                    completionHandler(.failure(.parsing(details: "RequestSignedUrl: Could not parse signed requests")))
                    return
                }
                completionHandler(.success((signedUrl, fileUrl)))
            }
        }
    }
    
    func submitOrder(parameters: [String: Any], completionHandler: @escaping (Result<String, APIClientError>) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderSubmission
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { result in
            
            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let response):
                let orderId = (response as? [String: Any])?["order_id"] as? String
                
                if let responseError = (response as? [String: Any])?["error"] as? [String: Any] {
                    guard let message = responseError["message"] as? String,
                        let errorCodeString = responseError["code"] as? String,
                        let errorCode = Int(errorCodeString)
                        else {
                            completionHandler(.failure(.parsing(details: "SubmitOrder: Missing error info")))
                            return
                    }
                    
                    if errorCode == 20, let orderId = orderId {
                        // This is not actually an error, we can report success.
                        completionHandler(.success(orderId))
                        return
                    }
                    
                    completionHandler(.failure(.server(code: errorCode, message: message)))
                    return
                }
                
                if let orderId = orderId {
                    completionHandler(.success(orderId))
                    return
                }
                completionHandler(.failure(.generic))
            }
        }
    }
    
    func checkOrderStatus(receipt: String, completionHandler: @escaping (Result<(status: OrderSubmitStatus, receipt: String?), Error>) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderStatus + receipt
        APIClient.shared.get(context: .kite, endpoint: endpoint, parameters: nil, headers: kiteHeaders) { result in
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            
            guard let pollingData = (try? result.get()) as? [String: AnyObject] else {
                completionHandler(.failure(APIClientError.parsing(details: "CheckOrderStatus: Could not parse root object")))
                return
            }

            if let errorDictionary = pollingData["error"] as? [String: AnyObject] {
                guard let code = errorDictionary["code"] as? String else {
                    completionHandler(.failure(APIClientError.parsing(details: "CheckOrderStatus: Missing error code")))
                    return
                }
                
                if code == "E20", let receipt = errorDictionary["order_id"] as? String { // The order was successful but with a different (previously sent) print order id
                    completionHandler(.success((.validated, receipt)))
                } else if code == "P11" { // Payment error
                    completionHandler(.failure(KiteAPIClientError.paymentError))
                } else if let message = errorDictionary["message"] as? String {
                    completionHandler(.failure(APIClientError.server(code: 0, message: message)))
                } else {
                    completionHandler(.failure(APIClientError.generic))
                }
                return
            }
            
            guard let statusString = pollingData["status"] as? String,
                let status = OrderSubmitStatus.fromApiString(statusString)
                else {
                    completionHandler(.failure(APIClientError.generic))
                    return
            }
            
            completionHandler(.success((status, nil)))
        }
    }

    /// Retrieve PalPal and Stripe keys
    func getPaymentKeys(completionHandler: @escaping (Result<(paypalKey: String?, stripeKey: String?), APIClientError>) -> Void) {

        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.template + "/?limit=1"
        APIClient.shared.get(context: .kite, endpoint: endpoint, headers: kiteHeaders) { result in
            
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()

            //get objects for each product
            guard let jsonDict = response as? [String: Any],
                  let paymentKeys = jsonDict["payment_keys"] as? [String: Any]
            else {
                completionHandler(.failure(.parsing(details: "GetPaymentKeys: Could not parse root objects")))
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

            completionHandler(.success((payPalKey, stripeKey)))
        }
    }
    
    /// Loads shipping information for a given array of template IDs.
    func getShippingInfo(for templateIds: [String], completionHandler: @escaping (Result<[String: Any], APIClientError>) -> Void) {
        
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        let uniqueTemplatesIds = Set(templateIds)
        var templateIdString = ""
        for templateId in uniqueTemplatesIds {
            if templateId != uniqueTemplatesIds.first { templateIdString += "," }
            templateIdString += templateId
        }
        
        let endpoint = KiteAPIClient.apiVersion + Endpoints.shipping + "/?template_ids=\(templateIdString)"
        APIClient.shared.get(context: .kite, endpoint: endpoint, headers: kiteHeaders) { result in
            
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()

            //get objects for each product
            guard let jsonDict = response as? [String: Any],
                let objects = jsonDict["objects"] as? [String: Any]
                else {
                    completionHandler(.failure(.parsing(details: "GetShippingInfo: Could not parse root objects")))
                    return
            }
            
            var shippingInfo = [String: Any]()
            for object in objects {
                let templateId = object.key
                guard let dict = object.value as? [String: Any]
                    else {
                        completionHandler(.failure(.parsing(details: "GetShippingInfo: Could not parse region mapping. Missing object.")))
                        return
                }
                
                var regionShippingClasses = [String: [ShippingMethod]]()
                
                guard let regionMappings = dict["country_to_region_mapping"] as? [String: [String]],
                    let shippingRegions = dict["shipping_regions"] as? [String: Any]
                    else {
                        completionHandler(.failure(.parsing(details: "GetShippingInfo: Could not parse region mapping")))
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
                                completionHandler(.failure(.parsing(details: "GetShippingInfo: Could not parse shipping class")))
                                return
                            }
                            shippingClasses.append(shippingClass)
                        }
                    }
                    regionShippingClasses[region] = shippingClasses
                }
                
                if regionShippingClasses.keys.isEmpty { // Inconsistent
                    completionHandler(.failure(.parsing(details: "GetShippingInfo: zero shipping classes parsed")))
                    return
                }
                
                shippingInfo[templateId] = ["availableShippingMethods": regionShippingClasses, "countryToRegionMapping": regionMappings]
            }
            
            if shippingInfo.isEmpty {
                completionHandler(.failure(.parsing(details: "GetShippingInfo: No templates returned")))
                return
            }
            
            completionHandler(.success(shippingInfo))
        }
    }
    
    func getCost(order: Order, completionHandler: @escaping (Result<Cost, APIClientError>) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }
        
        var parameters = [String: Any]()
        parameters["currencies"] = [OrderManager.shared.preferredCurrencyCode]
        
        if let promoCode = order.promoCode {
            parameters["payment"] = ["promo_code": promoCode]
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
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { result in
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()

            guard let responseDictionary = response as? [String: Any], let cost = Cost.parseDetails(dictionary: responseDictionary) else {
                completionHandler(.failure(.parsing(details: "GetCost: Could not parse cost")))
                return
            }
            
            completionHandler(.success(cost))
        }
    }
    
    // MARK: - Stripe
    func createStripeCustomer(_ completionHandler: @escaping (Result<String, APIClientError>) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        guard urlScheme != nil else {
            fatalError("Missing URL Scheme: PhotobookSDK.shared.kiteUrlScheme")
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.createStripeCustomer
        APIClient.shared.post(context: .kite, endpoint: endpoint, headers: kiteHeaders) { result in
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()
            
            guard let res = response as? [String: Any], let customerId = res["stripe_customer_id"] as? String else {
                completionHandler(.failure(.parsing(details: "CreateStripeCustomer: Could not parse customer ID")))
                return
            }
            
            completionHandler(.success(customerId))
        }
    }
    
    func createPaymentIntentWithSourceId(_ sourceId: String, amount: Double, currency: String, completionHandler: @escaping (Result<STPPaymentIntent, APIClientError>) -> Void)
    {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        guard let urlScheme = urlScheme else {
            fatalError("Missing URL Scheme: PhotobookSDK.shared.kiteUrlScheme")
        }
        
        if stripeCustomerId == nil {
            stripeCustomerId = StripeCredentialsHandler.load()
        }
        
        guard let customerId = stripeCustomerId else {
            completionHandler(.failure(.generic))
            return
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.createStripePaymentIntent
        let parameters: [String: Any] = ["stripe_customer_id": customerId,
                                         "source": sourceId,
                                         "amount": amount,
                                         "currency": currency,
                                         "return_url": "\(urlScheme)://stripe-redirect"]
        
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { result in
            if case .failure(let error) = result {
                completionHandler(.failure(error))
                return
            }
            let response = try! result.get()

            guard let res = response as? [String: Any], let clientSecret = res["client_secret"] as? String else {
                completionHandler(.failure(.parsing(details: "CreatePaymentIntent: could not parse client")))
                return
            }
            
            STPAPIClient.shared().retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, error in
                guard error == nil, let paymentIntent = paymentIntent else {
                    completionHandler(.failure(.parsing(details: "CreatePaymentIntent: could not retrieve payment details")))
                    return
                }
                completionHandler(.success(paymentIntent))
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
            APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders) { result in
                if case .failure(let error) = result {
                    if case APIClientError.parsing = error {
                        // If there was a parsing error, chances are the customer ID is invalid
                        StripeCredentialsHandler.delete()
                    }
                    NotificationCenter.default.post(name: KiteApiNotificationName.failedToCreateCustomerKey, object: nil)
                    completion(nil, error)
                    return
                }
                let response = try! result.get()
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

        createStripeCustomer { [weak welf = self] result in
            if case .failure(let error) = result {
                NotificationCenter.default.post(name: KiteApiNotificationName.failedToCreateCustomerKey, object: nil)
                completion(nil, error)
                return
            }
            let customerId = try! result.get()

            welf?.stripeCustomerId = customerId
            StripeCredentialsHandler.save(customerId)
            requestEphemeralKey(for: customerId)
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
