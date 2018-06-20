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
        var name: String
        var price: String
        
        init(name: String, price: String) {
            self.name = name
            self.price = price
        }
        
        init?(_ dict: [String: Any]) {
            guard let name = dict["name"] as? String,
                let priceDict = dict["price"] as? [String:Any],
                let amountDouble = priceDict["amount"] as? Double,
                let currencyCode = priceDict["currencyCode"] as? String else {
                //invalid
                print("OrderSummary.Detail: couldn't initialise")
                return nil
            }
            
            self.init(name: name, price: Decimal(amountDouble).formattedCost(currencyCode: currencyCode))
        }
    }
    
    private(set) var details = [Detail]()
    private(set) var total: String
    private var pigBaseUrl: String
    
    private init(details: [Detail], total: String, pigBaseUrl: String) {
        self.details = details
        self.total = total
        self.pigBaseUrl = pigBaseUrl
    }
    
    static func parse(_ dict: [String:Any]) -> OrderSummary? {
        guard let dictionaries = dict["lineItems"] as? [[String:Any]],
            let totalDict = dict["total"] as? [String: Any],
            let totalDouble = totalDict["amount"] as? Double,
            let currencyCode = totalDict["currencyCode"] as? String,
            let imageUrl = dict["previewImageUrl"] as? String else {
            print("OrderSummary: couldn't initialise")
            return nil
        }
        
        var details = [Detail]()
        for d in dictionaries {
            if let detail = Detail(d) {
                details.append(detail)
            } else {
                return nil //all line items have to be valid
            }
        }
        
        return OrderSummary(details: details, total: Decimal(totalDouble).formattedCost(currencyCode: currencyCode), pigBaseUrl: imageUrl)
    }
    
    func previewImageUrl(withCoverImageUrl imageUrl: String, size: CGSize) -> URL? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let urlString = pigBaseUrl + "&image=" + imageUrl + "&size=\(width)x\(height)" + "&fill_mode=match"
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else { return nil }
        
        return url
    }
}
