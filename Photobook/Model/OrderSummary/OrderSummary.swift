//
//  OrderSummary.swift
//  Photobook
//
//  Created by Julian Gruber on 31/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummary {
    
    struct Price {
        let amount: Double
        let currencyCode: String
        var formatted: String? {
            get {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = currencyCode
                return formatter.string(from: NSNumber(value: amount))
            }
        }
        
        init(amount: Double, currencyCode: String) {
            self.amount = amount
            self.currencyCode = currencyCode
        }
        
        init?(_ dict: [String:Any]) {
            guard let amount = dict["amount"] as? Double, let currencyCode = dict["currencyCode"] as? String else {
                //invalid
                print("OrderSummary.Price: couldn't initialise")
                return nil
            }
            
            self.init(amount: amount, currencyCode: currencyCode)
        }
    }
    
    struct Detail {
        var name: String
        var price: Price
        
        init(name: String, price: Price) {
            self.name = name
            self.price = price
        }
        
        init?(_ dict: [String:Any]) {
            guard let name = dict["name"] as? String, let priceDict = dict["price"] as? [String:Any], let price = Price(priceDict) else {
                //invalid
                print("OrderSummary.Detail: couldn't initialise")
                return nil
            }
            
            self.init(name: name, price: price)
        }
    }
    
    var details = [Detail]()
    var total: Price?
    private var pigBaseUrl: String?
    
    private init(details: [Detail], total: Price, pigBaseUrl: String) {
        self.details = details
        self.total = total
        self.pigBaseUrl = pigBaseUrl
    }
    
    convenience init?(_ dict: [String:Any]) {
        guard let dictionaries = dict["lineItems"] as? [[String:Any]],
            let totalDict = dict["total"] as? [String: Any],
            let total = Price(totalDict),
            let imageUrl = dict["previewImageUrl"] as? String else {
            print("OrderSummary: couldn't initialise")
            return nil
        }
        
        var details = [Detail]()
        for d in dictionaries {
            if let detail = Detail(d) {
                details.append(detail)
            }
        }
        
        self.init(details: details, total: total, pigBaseUrl: imageUrl)
    }
    
    func previewImageUrl(withCoverImageUrl imageUrl: String, size: CGSize) -> URL? {
        
        guard let pigBaseUrl = pigBaseUrl else { return nil }
        
        let width = Int(size.width)
        let height = Int(size.height)
        
        let urlString = pigBaseUrl + "&image=" + imageUrl + "&size=\(width)x\(height)" + "&fill_mode=match"
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else { return nil }
        
        return url
    }
}
