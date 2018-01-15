//
//  Price.swift
//  Photobook
//
//  Created by Julian Gruber on 09/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct Price {
    var value:Float
    var currencyCode:String
    var currencySymbol:String
    var formatted:String {
        get {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = NSLocale.current
            formatter.currencyCode = currencyCode
            let s = formatter.string(from: NSNumber(value: value))
            return s ?? ""
        }
    }
    
    init(value:Float, currencyCode:String, currencySymbol:String) {
        self.value = value
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
    }
    
    init?(_ dictionary:[String:Any]) {
        guard let value = dictionary["value"] as? Float,
            let currencyCode = dictionary["currencyCode"] as? String,
            let currencySymbol = dictionary["currencySymbol"] as? String
            else { return nil }
        
        self.init(value: value, currencyCode: currencyCode, currencySymbol: currencySymbol)
    }
}
