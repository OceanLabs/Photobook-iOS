//
//  OrderSummaryItem.swift
//  Photobook
//
//  Created by Julian Gruber on 26/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryItem {
    var name:String
    var price:Price
    
    init(name:String, price:Price) {
        self.name = name
        self.price = price
    }
    
    convenience init?(_ dict:[String:Any]) {
        guard let name = dict["name"] as? String, let priceDict = dict["price"] as? [String:Any], let price = Price(priceDict) else {
            //invalid
            print("OrderSummaryItem: couldn't initialise object")
            return nil
        }
        
        self.init(name: name, price: price)
    }
}

