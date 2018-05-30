//
//  Order.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 04/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import Stripe

struct OrdersNotificationName {
    static let orderWasCreated = Notification.Name("ly.kite.sdk.orderWasCreated")
    static let orderWasSuccessful = Notification.Name("ly.kite.sdk.orderWasSuccessful")
}

class Order: Codable {

    // TODO: Get the supported currencies from the server and make sure the currency of the locale is supported. Otherwise fall back to USD, GBP, EUR, first supported, in that order of preference
    let currencyCode = Locale.current.currencyCode ?? "USD" //USD if locale unavailable
    var deliveryDetails: DeliveryDetails?
    var shippingMethod: Int?
    var paymentMethod: PaymentMethod? = PaymentAuthorizationManager.isApplePayAvailable ? .applePay : nil
    var products = [PhotobookProduct]()
    var promoCode: String?
    var lastSubmissionDate: Date?
    var orderId: String?
    var paymentToken: String?
    
    var cachedCost: Cost?
    var validCost: Cost? {
        return hasValidCachedCost ? cachedCost : nil
    }
    
    var orderIsFree: Bool {
        var orderIsFree = false
        if let cost = validCost, let selectedMethod = shippingMethod, let shippingMethod = cost.shippingMethod(id: selectedMethod){
            orderIsFree = shippingMethod.totalCost == 0.0
        }
        
        return orderIsFree
    }
    
    var hashValue: Int {
        var stringHash = ""
        if let deliveryDetails = deliveryDetails { stringHash += "ad:\(deliveryDetails.hashValue)," }
        if let promoCode = promoCode { stringHash += "pc:\(promoCode)," }
        
        //TODO: include shipping options
        
        var productsHash: Int = 0
        for product in products {
            productsHash = productsHash ^ product.hashValue
        }
        
        return stringHash.hashValue ^ productsHash
    }
    
    var hasValidCachedCost: Bool {
        return cachedCost?.orderHash == hashValue
    }
    
    func updateCost(forceUpdate: Bool = false, _ completionHandler: @escaping (_ error : Error?) -> Void) {
        
        // TODO: REMOVEME. Mock cost & shipping methods
        let lineItem = LineItem(id: 0, name: "Clown Costume 🤡", cost: Decimal(integerLiteral: 10), formattedCost: "$10")
        let shippingMethod = ShippingMethod(id: 1, name: "Fiesta Deliveries 🎉🚚", shippingCostFormatted: "$5", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$15", maxDeliveryTime: 150, minDeliveryTime: 100)
        let shippingMethod2 = ShippingMethod(id: 2, name: "Magic Unicorn ✨🦄✨", shippingCostFormatted: "$5000", totalCost: Decimal(integerLiteral: 15), totalCostFormatted: "$5010", maxDeliveryTime: 1, minDeliveryTime: 0)
        
        let validPromoCode = "kite"
        let promoDiscount = validPromoCode == promoCode ? "-£5.00" : nil
        var promoCodeInvalidReason:String?
        if promoCode != nil && promoDiscount == nil {
            promoCodeInvalidReason = NSLocalizedString("Checkout/PromoCodeIsInvalid", value: "Invalid code 🤷", comment: "Label that informs the user that the promo code they have entered is not valid")
        }
        
        self.cachedCost = Cost(hash: hashValue, lineItems: [lineItem], shippingMethods: [shippingMethod, shippingMethod2], promoDiscount: promoDiscount, promoCodeInvalidReason: promoCodeInvalidReason)
        if self.shippingMethod == nil { self.shippingMethod = 1 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completionHandler(nil)
        }
    }
    
    func orderParameters() -> [String: Any] {
        var shippingAddress = deliveryDetails?.address?.jsonRepresentation()
        shippingAddress?["recipient_first_name"] = deliveryDetails?.firstName
        shippingAddress?["recipient_last_name"] = deliveryDetails?.lastName
        shippingAddress?["recipient_name"] = deliveryDetails?.fullName
        
        var parameters = [String: Any]()
        parameters["payment_charge_token"] = paymentToken
        parameters["shipping_address"] = shippingAddress
        parameters["customer_email"] = deliveryDetails?.email
        parameters["customer_phone"] = deliveryDetails?.phone
        parameters["promo_code"] = promoCode
        parameters["shipping_method"] = shippingMethod
        
        var jobs = [[String: Any]]()
        
        for product in products {
            jobs.append([
                "template_id" : product.template.productTemplateId ?? "",
                "multiples" : product.itemCount
                ])
        }
        
        parameters["jobs"] = jobs
        
        return parameters
    }
    
    func assetsToUpload() -> [Asset] {
        var assets = [Asset]()
        
        for product in products {
            let productAssets = product.assetsToUpload()
            for asset in productAssets {
                if !assets.contains(where: { $0.identifier == asset.identifier }) {
                    assets.append(asset)
                }
            }
        }
        
        return assets
    }
    
    func remainingAssetsToUpload() -> [Asset] {
        return assetsToUpload().filter({ $0.uploadUrl == nil })
    }
    
}
