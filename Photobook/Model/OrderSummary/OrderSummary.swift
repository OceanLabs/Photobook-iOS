//
//  OrderSummary.swift
//  Photobook
//
//  Created by Julian Gruber on 31/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummary {
    
    struct Detail {
        var name:String
        var price:String
        
        init(name:String, price:String) {
            self.name = name
            self.price = price
        }
        
        init?(_ dict:[String:Any]) {
            guard let name = dict["name"] as? String, let price = dict["price"] as? String else {
                //invalid
                print("OrderSummary.Detail: couldn't initialise")
                return nil
            }
            
            self.init(name: name, price: price)
        }
    }
    
    var details = [Detail]()
    var total:String?
    private var pigBaseUrl:String?
    
    private init(details:[Detail], total:String, pigBaseUrl:String) {
        self.details = details
        self.total = total
        self.pigBaseUrl = pigBaseUrl
    }
    
    convenience init?(_ dict:[String:Any]) {
        guard let dictionaries = dict["details"] as? [[String:Any]], let imageUrl = dict["imagePreviewUrl"] as? String, let total = dict["total"] as? String else {
            print("OrderSummary: couldn't initialise")
            return nil
        }
        
        var details = [Detail]()
        for d in dictionaries {
            if let detail = Detail(d) {
                details.append(detail)
            }
        }
        
        self.init(details:details, total:total, pigBaseUrl:imageUrl)
    }
    
    func previewImageUrl(withCoverImageUrl imageUrl:String, size:CGSize) -> URL? {
        
        guard let pigBaseUrl = pigBaseUrl else { return nil }
        
        let urlString = pigBaseUrl + "&image=" + imageUrl + "&size=\(size.width)x\(size.height)" + "&fill_mode=fit"
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else { return nil }
        
        return url
    }
    
}
