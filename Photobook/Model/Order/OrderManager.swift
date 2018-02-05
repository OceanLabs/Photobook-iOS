//
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 02/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderManager {

    var currencyCode: String? // TODO: Get this from somewhere
    var deliveryDetails: DeliveryDetails?
    var shippingMethod: Int?
    var paymentMethod: PaymentMethod?
    
    var cachedCost: Cost?
    var validCost: Cost? {
        return hasValidCachedCost ? cachedCost : nil
    }
    func updateCost(forceUpdate: Bool = false, _ completionHandler: @escaping (_ error : Error?) -> Void) {
        // TODO: update cost
        completionHandler(nil)
    }
    var hasValidCachedCost: Bool {
        // TODO: validate
        //        return cachedCost?.orderHash == self.hashValue
        return true
    }
    var paymentToken: String?

    static let shared = OrderManager()
    
    init() {
        // TODO: REMOVEME. Mock cost & shipping methods
        let lineItem = LineItem(id: 0, name: "Clown Costume 🤡", cost: Decimal(integerLiteral: 10), formattedCost: "$10")
        let shippingMethod = ShippingMethod(id: 1, name: "Fiesta Deliveries 🎉🚚", shippingCostFormatted: "$5", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$15", maxDeliveryTime: 150, minDeliveryTime: 100)
        let shippingMethod2 = ShippingMethod(id: 2, name: "Magic Unicorn ✨🦄✨", shippingCostFormatted: "$5000", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$5010", maxDeliveryTime: 1, minDeliveryTime: 0)
        self.cachedCost = Cost(hash: 0, lineItems: [lineItem], shippingMethods: [shippingMethod, shippingMethod2], promoDiscount: nil, promoCodeInvalidReason: nil)
    }
}
