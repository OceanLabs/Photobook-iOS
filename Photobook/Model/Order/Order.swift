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
    
    var orderDescription: String? {
        guard products.count > 0 else { return nil }
        
        if products.count == 1 {
            return products.first!.template.name
        }
        
        return String(format: NSLocalizedString("Order/Description", value: "%@ & %d others", comment: "Description of an order"), products.first!.template.name, products.count - 1)
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
        
        let getCostClosure = {
            KiteAPIClient.shared.getCost(order: self) { [weak self] (cost, error) in
                self?.cachedCost = cost
                cost?.orderHash = self?.hashValue ?? 0
                completionHandler(error)
            }
        }
        
        if availableShippingMethods == nil || forceShippingMethodUpdate {
            updateShippingMethods { (error) in
                getCostClosure()
            }
        } else {
            getCostClosure()
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
    
    func setShippingMethod(_ index: Int, forSection section: Int) {
        guard let availableShippingMethods = availableShippingMethods, availableShippingMethods.count > section,
            var selectedShippingMethods = selectedShippingMethods, selectedShippingMethods.count > section else {
                return
        }
        selectedShippingMethods[section] = availableShippingMethods[section][index]
    }
    
    func orderParameters() -> [String: Any]? {
        
        guard let selectedShippingMethods = selectedShippingMethods, selectedShippingMethods.count == products.count else {
            return nil
        }
        
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
        for (index, product) in products.enumerated() {
            
            guard let options = product.upsoldOptions,
                let insideUrl = product.insidePdfUrl,
                let coverUrl = product.coverPdfUrl else { return nil }
            
            let shippingMethod = selectedShippingMethods[index]
            
            let job: [String: Any] = [
                "template_id" : product.template.templateId,
                "multiples" : product.itemCount,
                "shipping_class" : shippingMethod.id,
                "options" : options,
                "inside_pdf" : insideUrl,
                "cover_pdf" : coverUrl
            ]
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
