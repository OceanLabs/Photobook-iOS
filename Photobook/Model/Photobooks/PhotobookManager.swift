//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

class PhotobookManager {
    
    static let shared = PhotobookManager()
    
    private struct endPoints {
        static let products = "/products"
        static let layouts = "/products/%d/layouts/interior"
    }
    
    var photobooks: [Photobook]?
    
    func requestPhotobooks(completion:@escaping (Error?) -> ()) {
        
        APIClient.shared.get(context: .pdfGenerator, endpoint: endPoints.products, parameters: nil) { [weak welf = self] (jsonData, error) in
            
            guard error == nil, let photobookData = jsonData as? [[String: AnyObject]] else {
                completion(error!)
                return
            }
            
            var tempPhotobooks = [Photobook]()
            
            for photobookDictionary in photobookData {
                if let photobook = Photobook.parse(dictionary: photobookDictionary) {
                    tempPhotobooks.append(photobook)
                }
            }
            
            welf?.photobooks = tempPhotobooks

            completion(nil)
        }
    }
    
    func requestLayouts(for photobook: Photobook, completion:@escaping (Error?) -> ()) {
        
        let endpoint = String(format: endPoints.layouts, photobook.productId)
        APIClient.shared.get(context: .pdfGenerator, endpoint: endpoint, parameters: nil) { (jsonData, error) in
            
            guard error == nil, let layoutsData = jsonData as? [[String: AnyObject]] else {
                completion(error!)
                return
            }
            
            // TODO: Populate parsing error
            photobook.parseLayouts(from: layoutsData)
            if photobook.layouts.count == 0 {
                print("PBManager: parsing layouts failed!")
                completion(nil)
            }
            
            completion(nil)
        }
    }
}
