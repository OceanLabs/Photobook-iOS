//
//  UIImageExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

extension UIImage {
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    public static func async(_ url:String, completion:@escaping (_ success:Bool, _ image:UIImage?) -> Void) {
        guard let url = URL(string: url) else {
            completion(false, nil)
            return
        }
        UIImage.async(url, completion: completion)
    }
    
    public static func async(_ url:URL, completion:@escaping (_ success:Bool, _ image:UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if let error = error {
                    completion(false, nil)
                    print(error)
                    return
                }
                let image = UIImage(data: data!)
                completion(true, image)
            })
            
        }).resume()
    }
}

