//
//  KiteAPIClient.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class KiteAPIClient {
    
    var apiKey: String?
    
    private struct Endpoints {
        static let endpointVersion = "v4.0"
        static let orderSubmission = endpointVersion + "/print"
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
        
        APIClient.shared.post(context: .kite, endpoint: Endpoints.orderSubmission, parameters: parameters, headers: kiteHeaders, completion: { response, error in
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

}
