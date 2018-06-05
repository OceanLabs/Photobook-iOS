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
    let shippingCostFormatted: String
    let totalCost: Decimal
    let totalCostFormatted: String
    let maxDeliveryTime: Int
    let minDeliveryTime: Int
    var totalCostRounded: NSDecimalNumber {
        return (totalCost as NSDecimalNumber).rounding(accordingToBehavior: CurrencyRoundingBehavior())
    }

    var deliveryTime: String {
        return String.localizedStringWithFormat(NSLocalizedString("ShippingMethod/DeliveryTime", value:"%d to %d working days", comment: "Delivery estimates for a specific delivery method"), minDeliveryTime, maxDeliveryTime)
    }
    
    init(id: Int, name: String, shippingCostFormatted: String, totalCost: Decimal, totalCostFormatted: String, maxDeliveryTime: Int, minDeliveryTime: Int) {
        self.id = id
        self.name = name
        self.shippingCostFormatted = shippingCostFormatted
        self.totalCost = totalCost
        self.totalCostFormatted = totalCostFormatted
        self.maxDeliveryTime = maxDeliveryTime
        self.minDeliveryTime = minDeliveryTime
    }

    static func parse(dictionary: [String: Any]) -> ShippingMethod? {
        guard
            let id = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let shippingCostDictionary = dictionary["shipping_cost"] as? [String: Any],
            let shippingCostAmount = shippingCostDictionary["amount"] as? String,
            let shippingCostCurrency = shippingCostDictionary["currency"] as? String,
            let shippingCost = Decimal(string: shippingCostAmount),

            let totalCostDictionary = dictionary["total_order_cost"] as? [String: Any],
            let totalCostAmount = totalCostDictionary["amount"] as? String,
            let totalCostCurrency = totalCostDictionary["currency"] as? String,
            let totalCost = Decimal(string: totalCostAmount),
        
            let deliveryTime = dictionary["deliver_time"] as? [String: Any],
            let maxDeliveryTime = deliveryTime["max_days"] as? Int,
            let minDeliveryTime = deliveryTime["min_days"] as? Int
            else { return nil }

        let shippingCostFormatted = shippingCost == 0 ? NSLocalizedString("free", value: "FREE", comment: "When shipping cost is 0")
                                                      : shippingCost.formattedCost(currencyCode: shippingCostCurrency)
        let totalCostFormatted = totalCost.formattedCost(currencyCode: totalCostCurrency)

        return ShippingMethod(id: id, name: name, shippingCostFormatted: shippingCostFormatted, totalCost: totalCost, totalCostFormatted: totalCostFormatted, maxDeliveryTime: maxDeliveryTime, minDeliveryTime: minDeliveryTime)
    }
}
