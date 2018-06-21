//
//  ShippingMethod.swift
//  Shopify
//
//  Created by Jaime Landazuri on 20/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

class ShippingMethod: Codable {
    
    static var supportsSecureCoding = true
    
    let id: Int
    let name: String
    let price: Price
    let maxDeliveryTime: Int
    let minDeliveryTime: Int

    var deliveryTime: String {
        return String.localizedStringWithFormat(NSLocalizedString("ShippingMethod/DeliveryTime", value:"%d to %d working days", comment: "Delivery estimates for a specific delivery method"), minDeliveryTime, maxDeliveryTime)
    }
    
    init(id: Int, name: String, price: Price, maxDeliveryTime: Int, minDeliveryTime: Int) {
        self.id = id
        self.name = name
        self.price = price
        self.maxDeliveryTime = maxDeliveryTime
        self.minDeliveryTime = minDeliveryTime
    }
    
    static func parse(dictionary: [String: Any]) -> ShippingMethod? {
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["mobile_shipping_name"] as? String,
            let costsDictionaries = dictionary["costs"] as? [[String: Any]],
            
            let price = Price.parse(costsDictionaries),
            
            let maxDeliveryTime = dictionary["max_delivery_time"] as? Int,
            let minDeliveryTime = dictionary["min_delivery_time"] as? Int
            else { return nil }
        
        return ShippingMethod(id: id, name: name, price: price, maxDeliveryTime: maxDeliveryTime, minDeliveryTime: minDeliveryTime)
    }
}
