//
//  LineItem.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class LineItem: Codable {
    
    let templateId: String
    let name: String
    let price: Price
    let identifier: String
    
    init(templateId: String, name: String, price: Price, identifier: String) {
        self.templateId = templateId
        self.name = name
        self.price = price
        self.identifier = identifier
    }
    
    static func parseDetails(dictionary: [String: Any], prioritizedCurrencyCodes: [String] = OrderManager.shared.prioritizedCurrencyCodes,  formattingLocale: Locale = Locale.current) -> LineItem? {
        guard
            let templateId = dictionary["template_id"] as? String,
            let name = dictionary["description"] as? String,
            let costDictionary = dictionary["product_cost"] as? [String: Any],
            let cost = Price.parse(costDictionary, prioritizedCurrencyCodes: prioritizedCurrencyCodes, formattingLocale: formattingLocale),
            let identifier = dictionary["job_id"] as? String
            else { return nil }
        
        return LineItem(templateId: templateId, name: name, price: cost, identifier: identifier)
    }
}
