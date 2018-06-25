//
//  Cost.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 13/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class Cost: Codable {
    
    var orderHash: Int
    let lineItems: [LineItem]?
    let totalShippingCost: Price?
    let total: Price?
    let promoDiscount: Price?
    let promoCodeInvalidReason: String?
    
    init(hash: Int, lineItems: [LineItem]?, totalShippingCost: Price, total: Price, promoDiscount: Price?, promoCodeInvalidReason: String?){
        self.orderHash = hash
        self.lineItems = lineItems
        self.totalShippingCost = totalShippingCost
        self.total = total
        self.promoDiscount = promoDiscount
        self.promoCodeInvalidReason = promoCodeInvalidReason
    }
    
    static func parseDetails(dictionary: [String: Any]) -> Cost? {
        guard let lineItemsDictionary = dictionary["line_items"] as? [[String: Any]],
            let totalShippingCostDictionary = dictionary["total_shipping_cost"] as? [String: Any],
            let totalDictionary = dictionary["total"] as? [String: Any],
            let totalShippingCost = Price.parse(totalShippingCostDictionary),
            let total = Price.parse(totalDictionary) else { return nil }
        
        var promoDiscount: Price?
        var promoInvalidMessage: String?
        
        if let promoCode = dictionary["promo_code"] as? [String: Any] {
            if (promoCode["invalid_message"] as? String) != nil {
                promoInvalidMessage = NSLocalizedString("Model/Cost/PromoInvalidMessage", value: "Invalid code", comment: "An invalid promo code has been entered and couldn't be applied to the order")//use generic localised string because response isn't optimised for mobile
            } else if let discount = promoCode["discount"] as? [String: Any] {
                promoDiscount = Price.parse(discount)
            }
        }
        
        var lineItems = [LineItem]()
        for item in lineItemsDictionary {
            guard let lineItem = LineItem.parseDetails(dictionary: item) else { return nil }
            lineItems.append(lineItem)
        }
        
        return Cost(hash: 0, lineItems: lineItems, totalShippingCost: totalShippingCost, total: total, promoDiscount: promoDiscount, promoCodeInvalidReason: promoInvalidMessage)
    }
}
