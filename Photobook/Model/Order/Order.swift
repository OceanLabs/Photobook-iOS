//
//  Order.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 04/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct OrdersNotificationName {
    static let orderWasCreated = Notification.Name("ly.kite.sdk.orderWasCreated")
    static let orderWasSuccessful = Notification.Name("ly.kite.sdk.orderWasSuccessful")
}

class Order: Codable {
    
    var deliveryDetails: DeliveryDetails?
    var paymentMethod: PaymentMethod? = PaymentAuthorizationManager.isApplePayAvailable ? .applePay : nil
    var products = [Product]()
    var promoCode: String?
    var lastSubmissionDate: Date?
    var orderId: String?
    var paymentToken: String?
    
    #if DEBUG
    func setCachedCost(_ price: Cost?) {
        cachedCost = price
    }
    #endif
    
    private var cachedCost: Cost?
    var cost: Cost? {
        return hasValidCachedCost ? cachedCost : nil
    }
    
    var orderIsFree: Bool {
        var orderIsFree = false
        
        if let cost = cost {
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
    
    var hasCachedCost: Bool {
        return cachedCost != nil
    }
    
    var hasValidCachedCost: Bool {
        return cachedCost?.orderHash == hashValue
    }
    
    func updateCost(forceUpdate: Bool = false, forceShippingMethodUpdate: Bool = false, _ completionHandler: @escaping (_ error : APIClientError?) -> Void) {
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
                
                if let error = error, case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }

                completionHandler(error)
            }
        }
        
        // If any product in the order doesn't not have shipping options, fetch shipping options for all
        let shouldUpdateShippingMethods = products.reduce(forceShippingMethodUpdate, { $0 || $1.template.availableShippingMethods == nil })
        
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
    
    func updateShippingMethods(_ completionHandler: @escaping (_ error: APIClientError?) -> Void) {
        KiteAPIClient.shared.fetchTemplateInfo(for: OrderManager.shared.basketOrder.products.map({ $0.template.templateId })) { [weak welf = self] (shippingMethods, error) in
            guard error == nil else {
                if let error = error, case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                }
                completionHandler(error)
                return
            }
            
            for product in welf?.products ?? [] {
                let availableShippingMethods = shippingMethods?[product.template.templateId]
                product.template.availableShippingMethods = availableShippingMethods
                product.selectedShippingMethod = availableShippingMethods?.first
            }
            completionHandler(nil)
        }
    }
    
    func orderParameters() -> [String: Any]? {
        
        guard let finalTotalCost = cost?.total else {
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
    
    private enum CodingKeys: String, CodingKey {
        case deliveryDetails, paymentMethod, products, promoCode, lastSubmissionDate, orderId, paymentToken, cachedCost
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(deliveryDetails, forKey: .deliveryDetails)
        try container.encodeIfPresent(paymentMethod, forKey: .paymentMethod)
        try container.encodeIfPresent(promoCode, forKey: .promoCode)
        try container.encodeIfPresent(lastSubmissionDate, forKey: .lastSubmissionDate)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encodeIfPresent(paymentToken, forKey: .paymentToken)
        try container.encodeIfPresent(cachedCost, forKey: .cachedCost)
        
        let productData = NSKeyedArchiver.archivedData(withRootObject: products)
        try container.encode(productData, forKey: .products)
    }
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        deliveryDetails = try values.decodeIfPresent(DeliveryDetails.self, forKey: .deliveryDetails)
        paymentMethod = try values.decodeIfPresent(PaymentMethod.self, forKey: .paymentMethod)
        promoCode = try values.decodeIfPresent(String.self, forKey: .promoCode)
        lastSubmissionDate = try values.decodeIfPresent(Date.self, forKey: .lastSubmissionDate)
        orderId = try values.decodeIfPresent(String.self, forKey: .orderId)
        paymentToken = try values.decodeIfPresent(String.self, forKey: .paymentToken)
        cachedCost = try values.decodeIfPresent(Cost.self, forKey: .cachedCost)
        
        if let productData = try values.decodeIfPresent(Data.self, forKey: .products),
            let products = NSKeyedUnarchiver.unarchiveObject(with: productData) as? [Product] {
            self.products = products
        } else {
            throw OrderProcessingError.corruptData
        }
    }
    
    func assetsToUpload() -> [Asset] {
        var assets = [Asset]()
        
        for product in products {
            let productAssets = PhotobookAsset.assets(from: product.assetsToUpload()) ?? []
            for asset in productAssets {
                if !assets.contains(where: { $0 == asset }) {
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
