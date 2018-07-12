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
    }

}
