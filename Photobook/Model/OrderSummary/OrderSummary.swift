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
        var price:Price
        
        init(name:String, price:Price) {
            self.name = name
            self.price = price
        }
        
        init?(_ dict:[String:Any]) {
            guard let name = dict["name"] as? String, let priceDict = dict["price"] as? [String:Any], let price = Price(priceDict) else {
                //invalid
                print("OrderSummary.Detail: couldn't initialise")
                return nil
            }
            
            self.init(name: name, price: price)
        }
    }
    
    var details = [Detail]()
    private var pigBaseUrl:String?
    
    private init(details:[Detail], pigBaseUrl:String) {
        self.details = details
        self.pigBaseUrl = pigBaseUrl
    }
    
    convenience init?(_ dict:[String:Any]) {
        guard let dictionaries = dict["summary"] as? [[String:Any]], let imageUrl = dict["imagePreviewUrl"] as? String else {
            print("OrderSummary: couldn't initialise")
            return nil
        }
        
        var details = [Detail]()
        for d in dictionaries {
            if let detail = Detail(d) {
                details.append(detail)
            }
        }
        
        self.init(details:details, pigBaseUrl:imageUrl)
    }
    
    func previewImageUrl(withCoverImageUrl imageUrl:String, size:CGSize) -> String? {
        guard let pigBaseUrl = pigBaseUrl else { return nil }
        
        return pigBaseUrl + "&image=" + imageUrl + "&size=\(size.width)x\(size.height)" + "&fill_mode=fit"
    }
    
}
