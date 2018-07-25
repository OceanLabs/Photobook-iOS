//
//  Checkout.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 12/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

@objc public class Checkout: NSObject {
    
    @objc public static let shared = Checkout()
    
    @objc public func addProductToBasket(_ product: Product) {
        OrderManager.shared.basketOrder.products.insert(product, at: 0)
        OrderManager.shared.saveBasketOrder()
    }
    
    @objc public func numberOfItemsInBasket() -> Int {
        return OrderManager.shared.basketOrder.products.reduce(0, { $0 + $1.itemCount })
    }
    
    @objc public func setPromoCode(_ code: String?) {
        OrderManager.shared.basketOrder.promoCode = code
    }
    
    @objc public func clearBasketOrder() {
        OrderManager.shared.reset()
    }
    
    @objc public func setUserEmail(_ userEmail: String) {
        guard userEmail.isValidEmailAddress() else {
            return
        }
        
        let deliveryDetails = DeliveryDetails.loadLatestDetails() ?? DeliveryDetails()
        deliveryDetails.email = userEmail
        deliveryDetails.saveDetailsAsLatest()
    }
    
    @objc public func setUserPhone(_ userPhone: String) {
        guard userPhone.count >= FormConstants.minPhoneNumberLength else {
            return
        }
        
        let deliveryDetails = DeliveryDetails.loadLatestDetails() ?? DeliveryDetails()
        deliveryDetails.email = userPhone
        deliveryDetails.saveDetailsAsLatest()
    }

}
