//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

class PhotobookAPIManager {
    
    static let shared = PhotobookAPIManager()
    private var apiClient = APIClient.shared
    
    #if DEBUG
    convenience init(apiClient: APIClient) {
        self.init()
        self.apiClient = apiClient

    }
    #endif
    
    private struct endPoints {
        static let products = "/products"
    }
    
    func requestPhotobookInfo(completion:@escaping ([Photobook]?, [Layout]?, Error?) -> ()) {
        
        apiClient.get(context: .pdfGenerator, endpoint: endPoints.products, parameters: nil) { (jsonData, error) in            
            
            // TEMP: Fake api response. Don't run for tests.x
            var jsonData = jsonData
            if NSClassFromString("XCTest") == nil {
                jsonData = self.json(file: "photobooks")
            } else {
                if error != nil {
                    completion(nil, nil, error!)
                    return
                }
            }
            
            guard
                let photobooksData = jsonData as? [String: AnyObject],
                let productsData = photobooksData["products"] as? [[String: AnyObject]],
                let layoutsData = photobooksData["layouts"] as? [[String: AnyObject]]
            else {
                completion(nil, nil, APIClientError.parsing)
                return
            }
            
            // Parse layouts
            var tempLayouts = [Layout]()
            for layoutDictionary in layoutsData {
                if let layout = Layout.parse(layoutDictionary) {
                    tempLayouts.append(layout)
                }
            }
            
            if tempLayouts.count == 0 {
                print("PBManager: parsing layouts failed!")
                completion(nil, nil, APIClientError.parsing)
                return
            }
            
            // Parse photobook products
            var tempPhotobooks = [Photobook]()
            
            for photobookDictionary in productsData {
                if let photobook = Photobook.parse(photobookDictionary) {
                    tempPhotobooks.append(photobook)
                }
            }
            
            if tempPhotobooks.count == 0 {
                // TODO: Populate parsing error
                print("PBManager: parsing photobook products failed!")
                completion(nil, nil, APIClientError.parsing)
                return
            }

            completion(tempPhotobooks, tempLayouts, nil)
        }
    }
    
    private func json(file: String) -> AnyObject? {
        guard let path = Bundle.main.path(forResource: file, ofType: "json") else { return nil }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            return try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
        } catch {
            print("JSON: Could not parse file")
        }
        return nil
    }
}
