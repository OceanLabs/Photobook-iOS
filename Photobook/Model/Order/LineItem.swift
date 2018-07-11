//
//  LineItem.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class LineItem: Codable {
    
    let id: String
    let name: String
    let price: Price
    
    init(id: String, name: String, price: Price) {
        self.id = id
        self.name = name
        self.price = price
    }
    
    static func parseDetails(dictionary: [String: Any], localeCurrencyCode: String? = Locale.current.currencyCode,  formattingLocale: Locale = Locale.current) -> LineItem? {
        guard
            let id = dictionary["template_id"] as? String,
            let name = dictionary["description"] as? String,
            let costDictionary = dictionary["product_cost"] as? [String: Any],
            let cost = Price.parse(costDictionary, localeCurrencyCode: localeCurrencyCode, formattingLocale: formattingLocale)
            else { return nil }
        
        return LineItem(id: id, name: name, price: cost)
    }
}
