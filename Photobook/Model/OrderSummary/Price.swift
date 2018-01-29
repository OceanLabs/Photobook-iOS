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
    
    init(value:Float, currencyCode:String) {
        self.value = value
        self.currencyCode = currencyCode
    }
    
    init?(_ dict:[String:Any]) {
        let fallbackCurrencyCode = "USD"
        let currencyCode = Locale.current.currencyCode
        if let currencyCode = currencyCode, let parsedValue = dict[currencyCode] as? Float {
            //initialise with local currency
            self.init(value: parsedValue, currencyCode: currencyCode)
        } else if let parsedValue = dict[fallbackCurrencyCode] as? Float {
            //initialise with USD
            self.init(value: parsedValue , currencyCode: fallbackCurrencyCode)
        } else {
            //invalid
            print("Price: couldn't initialise object")
            return nil
        }
    }
}
