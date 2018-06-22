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
    let cost: Price
    
    init(id: String, name: String, cost: Price) {
        self.id = id
        self.name = name
        self.cost = cost
    }
    
    static func parseDetails(dictionary: [String: Any]) -> LineItem? {
        guard
            let id = dictionary["template_id"] as? String,
            let name = dictionary["description"] as? String,
            let costDictionary = dictionary["product_cost"] as? [String: Any],
            let cost = Price.parse(costDictionary)
            else { return nil }
        
        return LineItem(id: id, name: name, cost: cost)
    }
}
