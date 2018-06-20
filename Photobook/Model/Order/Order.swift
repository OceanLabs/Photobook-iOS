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
    
    let currencyCode = Locale.current.currencyCode ?? "GBP" //GBP if locale unavailable
    var deliveryDetails: DeliveryDetails?
    var availableShippingMethods: [[ShippingMethod]]?
    var selectedShippingMethods: [ShippingMethod]?
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
        
        if let cost = validCost {
            orderIsFree = cost.total?.value == 0.0
        }
        
        return orderIsFree
    }
    
    var hashValue: Int {
        var stringHash = ""
        if let deliveryDetails = deliveryDetails { stringHash += "ad:\(deliveryDetails.hashValue)," }
        if let promoCode = promoCode { stringHash += "pc:\(promoCode)," }
        
        var shippingHash: Int = 0
        if let shippingMethods = selectedShippingMethods {
            for shippingMethod in shippingMethods {
                shippingHash = shippingHash ^ shippingMethod.id
            }
        }
        
        var productsHash: Int = 0
        for product in products {
            productsHash = productsHash ^ product.hashValue
            
        }
        
        return stringHash.hashValue ^ shippingHash ^ productsHash
    }
    
    var hasValidCachedCost: Bool {
        return cachedCost?.orderHash == hashValue
    }
    
    func updateCost(forceUpdate: Bool = false, forceShippingMethodUpdate: Bool = false, _ completionHandler: @escaping (_ error : Error?) -> Void) {
        
        if hasValidCachedCost && !forceUpdate {
            completionHandler(nil)
            return
        }
        
        if availableShippingMethods == nil || forceShippingMethodUpdate {
            updateShippingMethods { (error) in
                KiteAPIClient.shared.getCost(order: self) { [weak self] (cost, error) in
                    self?.cachedCost = cost
                    cost?.orderHash = self?.hashValue ?? 0
                    completionHandler(nil)
                }
            }
        } else {
            KiteAPIClient.shared.getCost(order: self) { [weak self] (cost, error) in
                self?.cachedCost = cost
                cost?.orderHash = self?.hashValue ?? 0
                completionHandler(nil)
            }
        }
    }
    
    private func updateShippingMethods(_ completionHandler: @escaping (_ error : Error?) -> Void) {
        KiteAPIClient.shared.getShippingMethods(order: OrderManager.shared.basketOrder) { [weak self] (shippingMethods, error) in
            self?.availableShippingMethods = shippingMethods
            
            //preset
            self?.presetShippingOptions()
            completionHandler(error)
        }
    }
    
    private func presetShippingOptions() {
        guard let availableShippingMethods = self.availableShippingMethods else {
            return
        }
        
        selectedShippingMethods = [ShippingMethod]()
        for shippingMethods in availableShippingMethods {
            if let firstMethod = shippingMethods.first {
                selectedShippingMethods?.append(firstMethod) //not set yet, set default (first method)
            }
        }
    }
    
    func orderParameters(withPdfUrls urls: [String]) -> [String: Any]? {
        
        guard let shippingMethod = selectedShippingMethods?.first,
            let product = products.first,
            urls.count == 2 else { return nil }
        
        let insideUrl = urls[0]
        let coverUrl = urls[1]
        
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
        
        var jobs = [[String: Any]]()
        //currently only one photobook possible. so use first item
        var job: [String: Any] = [
            "template_id" : product.template.productTemplateId,
            "multiples" : product.itemCount,
            "shipping_class" : shippingMethod.id,
            "inside_pdf" : insideUrl,
            "cover_pdf" : coverUrl
            ]
        if let options = product.upsoldOptions { job["options"] = options }
        jobs.append(job)
        
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
