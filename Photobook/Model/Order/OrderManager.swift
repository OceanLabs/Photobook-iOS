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

    static let shared = OrderManager()
}
