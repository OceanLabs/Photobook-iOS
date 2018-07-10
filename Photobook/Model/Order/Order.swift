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
    
    var deliveryDetails: DeliveryDetails?
    var paymentMethod: PaymentMethod? = PaymentAuthorizationManager.isApplePayAvailable ? .applePay : nil
    var products = [PhotobookProduct]()
    var promoCode: String?
    var lastSubmissionDate: Date?
    var orderId: String?
    var paymentToken: String?
    
    #if DEBUG
    func setCachedCost(_ cost: Cost?) {
        cachedCost = cost
    }
    #endif
    
    private var cachedCost: Cost?
    var validCost: Cost? {
        return hasValidCachedCost ? cachedCost : nil
    }
    
    var orderIsFree: Bool {
        var orderIsFree = false
        
        if let cost = validCost {
            orderIsFree = cost.total.value == 0.0
        }
        
        return orderIsFree
    }
    
    var orderDescription: String? {
        guard products.count > 0 else { return nil }
        
        if products.count == 1 {
            return products.first!.template.name
        }
        
        return String(format: NSLocalizedString("Order/Description", value: "%@ & %d others", comment: "Description of an order"), products.first!.template.name, products.count - 1)
    }
    
    var hashValue: Int {
        let country = deliveryDetails?.address?.country ?? Country.countryForCurrentLocale()
        var stringHash = "ad:\(country.codeAlpha3.hashValue),"
        if let promoCode = promoCode {
            stringHash += "pc:\(promoCode),"
        }
        
        var shippingHash: Int = 0
        var productsHash: Int = 0
        for product in products {
            productsHash = productsHash ^ product.hashValue
            shippingHash = shippingHash ^ (product.selectedShippingMethod?.id ?? 0)
        }
        
        return stringHash.hashValue ^ shippingHash ^ productsHash
    }
    
    var hasValidCachedCost: Bool {
        return cachedCost?.orderHash == hashValue
    }
    
    func updateCost(forceUpdate: Bool = false, forceShippingMethodUpdate: Bool = false, _ completionHandler: @escaping (_ error : Error?) -> Void) {
        guard products.count != 0,
        !hasValidCachedCost || forceUpdate
        else {
            completionHandler(nil)
            return
        }
        
        let getCostClosure = {
            KiteAPIClient.shared.getCost(order: self) { [weak self] (cost, error) in
                self?.cachedCost = cost
                cost?.orderHash = self?.hashValue ?? 0
                completionHandler(error)
            }
        }
        
        // If any product in the order doesn't not have shipping options, fetch shipping options for all
        let shouldUpdateShippingMethods = products.reduce(forceShippingMethodUpdate, { $0 || $1.availableShippingMethods == nil })
        
        if shouldUpdateShippingMethods {
            updateShippingMethods { (error) in
                guard error == nil else {
                    completionHandler(error)
                    return
                }
                getCostClosure()
            }
        } else {
            getCostClosure()
        }
        
        
        
    }
    
    func updateShippingMethods(_ completionHandler: @escaping (_ error : Error?) -> Void) {
        KiteAPIClient.shared.getShippingMethods(for: OrderManager.shared.basketOrder.products.map({ $0.template.templateId })) { [weak welf = self] (shippingMethods, error) in
            guard error == nil else {
                completionHandler(error)
                return
            }
            
            for product in welf?.products ?? [] {
                let availableShippingMethods = shippingMethods?[product.template.templateId]
                product.availableShippingMethods = availableShippingMethods
                product.selectedShippingMethod = availableShippingMethods?.first
            }
            completionHandler(nil)
        }
    }
    
    func orderParameters() -> [String: Any]? {
        
        guard let finalTotalCost = validCost?.total else {
                return nil
        }
        
        var shippingAddress = deliveryDetails?.address?.jsonRepresentation()
        shippingAddress?["recipient_first_name"] = deliveryDetails?.firstName
        shippingAddress?["recipient_last_name"] = deliveryDetails?.lastName
        shippingAddress?["recipient_name"] = deliveryDetails?.fullName
        
        var parameters = [String: Any]()
        parameters["proof_of_payment"] = paymentToken
        parameters["shipping_address"] = shippingAddress
        parameters["customer_email"] = deliveryDetails?.email
        parameters["customer_phone"] = deliveryDetails?.phone
        parameters["promo_code"] = promoCode
        parameters["customer_payment"] = [
            "currency": finalTotalCost.currencyCode,
            "amount": finalTotalCost.value
        ]
        
        var jobs = [[String: Any]]()
        for product in products {
            
            guard let job = product.orderParameters() else {
                return nil // If one product is invalid, we want the whole order to be invalid
            }
            jobs.append(job)
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
