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

@objc public class Checkout: NSObject {
    
    @objc public static let shared = Checkout()
    
    @objc public func addCurrentProductToBasket(items: Int = 1) {
        guard let product = ProductManager.shared.currentProduct else { return }
        product.itemCount = items
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
        
        let deliveryDetails = DeliveryDetails.selectedDetails() ?? DeliveryDetails()
        deliveryDetails.email = userEmail
        DeliveryDetails.saveDeliveryDetails()
    }
    
    @objc public func setUserPhone(_ userPhone: String) {
        guard userPhone.count >= FormConstants.minPhoneNumberLength else {
            return
        }
        
        let deliveryDetails = DeliveryDetails.selectedDetails() ?? DeliveryDetails()
        deliveryDetails.email = userPhone
        DeliveryDetails.saveDeliveryDetails()
    }

}
