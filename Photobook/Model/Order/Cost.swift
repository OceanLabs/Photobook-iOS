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
    let shippingMethods: [ShippingMethod]?
    let promoDiscount: String?
    let promoCodeInvalidReason: String?
    
    init(hash: Int, lineItems: [LineItem]?, shippingMethods: [ShippingMethod]?, promoDiscount: String?, promoCodeInvalidReason: String?) {
        self.orderHash = hash
        self.lineItems = lineItems
        self.shippingMethods = shippingMethods
        self.promoDiscount = promoDiscount
        self.promoCodeInvalidReason = promoCodeInvalidReason
    }
    
    func shippingMethod(id method: Int?) -> ShippingMethod? {
        return shippingMethods?.first { $0.id == method }
    }
    
    static func parseDetails(dictionary: [String: Any]) -> Cost? {
        guard let lineItemsDictionary = dictionary["line_items"] as? [[String: Any]],
              let shippingMethodsDictionary = dictionary["shipping_methods"] as? [[String: Any]] else { return nil }
        
        var promoDiscount: String?
        var promoInvalidMessage: String?
        
        if let promoCode = dictionary["promo_code"] as? [String: Any] {
            if let invalidMessage = promoCode["invalid_message"] as? String {
                promoInvalidMessage = invalidMessage
            } else if let discount = promoCode["discount"] as? [String: Any],
                let amount = discount["amount"] as? String,
                let discountAmount = Decimal(string:amount),
                discountAmount > 0,
                let currency = discount["currency"] as? String {
                
                promoDiscount = discountAmount.formattedCost(currencyCode: currency)
            }
        }
        
        var lineItems = [LineItem]()
        for item in lineItemsDictionary {
            if let lineItem = LineItem.parseDetails(dictionary: item) {
                lineItems.append(lineItem)
            }
        }

        var shippingMethods = [ShippingMethod]()
        for shippingMethodDictionary in shippingMethodsDictionary {
            if let shippingMethod = ShippingMethod.parse(dictionary: shippingMethodDictionary) {
                shippingMethods.append(shippingMethod)
            }
        }
        
        return Cost(hash: 0, lineItems: lineItems, shippingMethods: shippingMethods, promoDiscount: promoDiscount, promoCodeInvalidReason: promoInvalidMessage)
    }
}
