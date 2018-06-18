//
//  KiteAPIClient.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

enum OrderSubmitStatus: String {
    case cancelled, error, unknown, received, accepted, validated, processed
    
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
        APIClient.shared.post(context: .kite, endpoint: endpoint, parameters: parameters, headers: kiteHeaders, completion: { response, error in
            let orderId = (response as? [String: Any])?["print_order_id"] as? String
            
            if let responseError = (response as? [String: Any])?["error"] as? [String: Any] {
                guard let message = responseError["message"] as? String,
                    let errorCodeString = responseError["code"] as? String,
                    let errorCode = Int(errorCodeString)
                    else { completionHandler(nil, ErrorMessage(APIClientError.parsing)); return }
                
                if errorCode == 20 {
                    // This is not actually an error, we can report success.
                    completionHandler(orderId, nil)
                    return
                }
                
                completionHandler(nil, ErrorMessage(APIClientError.server(code: errorCode, message: message)))
            }
            
            if orderId != nil {
                completionHandler(orderId, nil)
            } else if let error = error {
                completionHandler(nil, ErrorMessage(error))
            } else {
                completionHandler(nil, ErrorMessage(text: CommonLocalizedStrings.somethingWentWrong))
            }
        })
    }
    
    func checkOrderStatus(receipt: String, completionHandler: @escaping (_ status: OrderSubmitStatus, _ error: ErrorMessage?, _ receipt: String?) -> Void) {
        guard apiKey != nil else {
            fatalError("Missing Kite API key: PhotobookSDK.shared.kiteApiKey")
        }

        let endpoint = KiteAPIClient.apiVersion + Endpoints.orderStatus + receipt
        APIClient.shared.get(context: .kite, endpoint: endpoint, parameters: nil, headers: kiteHeaders) { (response, error) in
            guard error == nil else {
                completionHandler(.error, ErrorMessage(error), nil)
                return
            }
            
            guard let pollingData = response as? [String: AnyObject] else {
                completionHandler(.error, ErrorMessage(.parsing), nil)
                return
            }

            if let errorDictionary = pollingData["error"] as? [String: AnyObject] {
                // The order was successful but with a different (previously sent) print order id
                if let code = errorDictionary["code"] as? String, code == "E20" {
                    let receipt = errorDictionary["print_order_id"] as? String
                    completionHandler(.validated, nil, receipt)
                    return
                }
                if let message = errorDictionary["message"] as? String {
                    completionHandler(.error, ErrorMessage(text: message), nil)
                    return
                }
            }
            
            guard let statusString = pollingData["status"] as? String,
                  let status = OrderSubmitStatus.fromApiString(statusString)
                else {
                    completionHandler(.error, ErrorMessage(.parsing), nil)
                    return
            }
            
            completionHandler(status, nil, nil)
        }
    }

}
