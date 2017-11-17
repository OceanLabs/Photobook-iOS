//
//  APIClient.swift
//  Photobook
//
//  Created by Jaime Landazuri on 16/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

enum APIClientError: Error {
    case parsing
    case connection
    case server(code: Int, message: String)
}

enum APIContext {
    case photobookApp
    case pdfGenerator
}

/// Network client for all interaction with the API
class APIClient {
    
    fileprivate enum HTTPMethod : String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }
    
    // Shared client
    static let shared = APIClient()
    
    private struct Constants {
        static let photobookGeneratorBaseURL = "https://photobook-builder.herokuapp.com/"
        static let errorDomain = "Photobook.APIClient.APIClientError"
    }
    
    // Create a custom url session
    private let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
    
    private func baseURLString(for context: APIContext) -> String {
        switch context {
        case .photobookApp: return "" // TBC
        case .pdfGenerator: return "https://photobook-builder.herokuapp.com/"
        }
    }

    // Generic dataTask handling function
    private func dataTask(context: APIContext, endpoint: String, parameters: [String : Any]?, method: HTTPMethod, completionHandler:@escaping (Error?, [String : AnyObject]?) -> ()) {
        
        var request = URLRequest(url: URL(string: baseURLString(for: context) + endpoint)!)
        
        request.httpMethod = method.rawValue
        
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        switch method {
        case .get:
            if parameters != nil {
                var components = URLComponents(string: request.url!.absoluteString)
                var items = [URLQueryItem]()
                for (key, value) in parameters! {
                    var itemValue = ""
                    if let value = value as? String {
                        itemValue = value
                    } else if let value = value as? Int {
                        itemValue = String(value)
                    } else {
                        fatalError("API client: Unsupported parameter type")
                    }
                    
                    let item = URLQueryItem(name: key, value: itemValue)
                    items.append(item)
                }
                components?.queryItems = items
                request.url = components?.url
            }
        case .post:
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let parameters = parameters {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        default:
            fatalError("API client: Unsupported HTTP method")
        }
        
        urlSession.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                let error = error as NSError?
                switch error!.code {
                case Int(CFNetworkErrors.cfurlErrorBadServerResponse.rawValue):
                    completionHandler(APIClientError.server(code: 500, message: ""), nil)
                case Int(CFNetworkErrors.cfurlErrorSecureConnectionFailed.rawValue) ..< Int(CFNetworkErrors.cfurlErrorUnknown.rawValue):
                    completionHandler(APIClientError.connection, nil)
                default:
                    completionHandler(APIClientError.server(code: error!.code, message: error!.localizedDescription), nil)
                }
                return
            }
            
            guard let data = data else {
                completionHandler(error, nil)
                return
            }
            
            // Attempt parsing to JSON
            guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : AnyObject] else {
                if let stringData = String(data: data, encoding: String.Encoding.utf8) {
                    print("API: \(stringData)")
                }
                completionHandler(APIClientError.parsing, nil)
                return
            }
            
            // Check if there's an error in the response
            let errorDict = json["error"] as? [String : AnyObject]
            if let errorMessage = (errorDict?["message"] as? [AnyObject])?.last as? String{
                completionHandler(APIClientError.server(code: (response as? HTTPURLResponse)?.statusCode ?? 0, message: errorMessage), nil)
            } else {
                completionHandler(nil, json)
            }
            
            }.resume()
    }
}

// MARK: - Public methods
extension APIClient {
    
    func post(context: APIContext, endpoint: String, parameters: [String : Any]?, completionHandler:@escaping (Error?, [String : AnyObject]?) -> ()) {
        dataTask(context: context, endpoint: endpoint, parameters: parameters, method: .post, completionHandler: completionHandler)
    }
    
    func get(context: APIContext, endpoint: String, parameters: [String : Any]?, completionHandler:@escaping (Error?, [String : AnyObject]?) -> ()) {
        dataTask(context: context, endpoint: endpoint, parameters: parameters, method: .get, completionHandler: completionHandler)
    }
    
    func put(context: APIContext, endpoint: String, parameters: [String : Any]?, completionHandler:@escaping (Error?, [String : AnyObject]?) -> ()) {
        dataTask(context: context, endpoint: endpoint, parameters: parameters, method: .put, completionHandler: completionHandler)
    }
    
}
