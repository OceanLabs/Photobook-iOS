//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

class Cost: Codable {
    
    var orderHash: Int
    let lineItems: [LineItem]
    let totalShippingPrice: Price
    let total: Price
    let promoDiscount: Price?
    let promoCodeInvalidReason: String?
    
    init(hash: Int, lineItems: [LineItem], totalShippingPrice: Price, total: Price, promoDiscount: Price?, promoCodeInvalidReason: String?){
        self.orderHash = hash
        self.lineItems = lineItems
        self.totalShippingPrice = totalShippingPrice
        self.total = total
        self.promoDiscount = promoDiscount
        self.promoCodeInvalidReason = promoCodeInvalidReason
    }
    
    static func parseDetails(dictionary: [String: Any]) -> Cost? {
        guard let shipmentsArray = dictionary["shipments"] as? [[String: Any]],
            let totalShippingCostDictionary = dictionary["total_shipping_costs"] as? [String: Any],
            let totalDictionary = dictionary["total_costs"] as? [String: Any],
            let totalShippingCost = Price.parse(totalShippingCostDictionary),
            let total = Price.parse(totalDictionary) else { return nil }
        
        var amendedTotal: Price?
        var promoDiscount: Price?
        var promoInvalidMessage: String?

        if let _ = dictionary["promo_error"] as? String {
            promoInvalidMessage = NSLocalizedString("Model/Cost/PromoInvalidMessage", value: "Invalid code", comment: "An invalid promo code has been entered and couldn't be applied to the order")//use generic localised string because response isn't optimised for mobile
        } else if let discount = dictionary["discount"] as? [String: Any],
                    let discountsApplied = discount["discounts_applied"] as? [String: Any],
                    let totalDiscount = discountsApplied["total"] as? [String: Any],
                    let amendedCosts = discount["amended_costs"] as? [String: Any],
                    let totalCost = amendedCosts["total"] as? [String: Any]
        {
            promoDiscount = Price.parse(totalDiscount)
            amendedTotal = Price.parse(totalCost)
        }
        
        var lineItems = [LineItem]()
        for shipment in shipmentsArray {
            for item in shipment["items"] as? [[String: Any]] ?? [] {
                guard let lineItem = LineItem.parseDetails(dictionary: item) else { return nil }
                lineItems.append(lineItem)
            }
        }
        
        return Cost(hash: 0, lineItems: lineItems, totalShippingPrice: totalShippingCost, total: amendedTotal ?? total, promoDiscount: promoDiscount, promoCodeInvalidReason: promoInvalidMessage)
    }
}
