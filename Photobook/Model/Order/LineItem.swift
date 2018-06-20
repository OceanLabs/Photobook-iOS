//
//  LineItem.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class LineItem: Codable {
    
    let id: Int
    let name: String
    let cost: Decimal
    let formattedCost: String
    
    init(id: Int, name: String, cost: Decimal, formattedCost: String) {
        self.id = id
        self.name = name
        self.cost = cost
        self.formattedCost = formattedCost
    }
    
    static func parseDetails(dictionary: [String: Any]) -> LineItem? {
        guard
            let id = dictionary["variant_id"] as? Int,
            let name = dictionary["description"] as? String,
            let costDictionary = dictionary["cost"] as? [String: Any],
            let amount = costDictionary["amount"] as? String,
            let cost = Decimal(string: amount),
            let currency = costDictionary["currency"] as? String
            else { return nil }
        
        let formattedCost = cost.formattedCost(currencyCode: currency)
        return LineItem(id: id, name: name, cost: cost, formattedCost: formattedCost)
    }
}
