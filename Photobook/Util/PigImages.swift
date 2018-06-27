//
//  Pig.swift
//  Photobook
//
//  Created by Jaime Landazuri on 27/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class Pig {
    
    static var apiClient = APIClient.shared
    
    static func fetchPreviewImage(withBaseUrlString baseUrlString: String, coverImageUrlString: String, size: CGSize, completion: @escaping (UIImage?) -> Void) {

        let width = Int(size.width)
        let height = Int(size.height)
        
        let urlString = baseUrlString + "&image=" + coverImageUrlString + "&size=\(width)x\(height)" + "&fill_mode=match"
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            completion(nil)
            return
        }

        apiClient.downloadImage(url) { (image, _) in
            completion(image)
        }
    }
}
