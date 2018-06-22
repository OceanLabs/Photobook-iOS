//
//  Cost.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 13/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import PassKit

class OrderCost: Codable {
    
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
    
    static func parseDetails(dictionary: [String : Any]) -> OrderCost? {
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
            }
            if let discount = promoCode["discount"] as? [String: Any] {
                promoDiscount = Price.parse(discount)
            }
        }
        
        var lineItems = [LineItem]()
        for item in lineItemsDictionary {
            guard let lineItem = LineItem.parseDetails(dictionary: item) else { return nil }
            lineItems.append(lineItem)
        }
        
        return OrderCost(hash: 0, lineItems: lineItems, totalShippingCost: totalShippingCost, total: total, promoDiscount: promoDiscount, promoCodeInvalidReason: promoInvalidMessage)
    }
    
    /// Create an array of PKPaymentSummaryItem from the order's lineItems and add item for total
    ///
    /// - Parameter payTo: A string that shows the user whom they are paying.
    /// - Returns: an array of PKPaymentSummaryItem that's appropriate for Apple Pay 
    func summaryItemsForApplePay(payTo: String) -> [PKPaymentSummaryItem]{
        guard
            let lineItems = self.lineItems,
            let totalCost = self.total?.value
            else { return [PKPaymentSummaryItem]() }
        
        var summaryItems = [PKPaymentSummaryItem]()
        for item in lineItems {
            summaryItems.append(PKPaymentSummaryItem(label: item.name, amount: item.cost.value as NSDecimalNumber))
        }
        
        summaryItems.append(PKPaymentSummaryItem(label: payTo, amount: totalCost as NSDecimalNumber))
        
        return summaryItems
    }
}
