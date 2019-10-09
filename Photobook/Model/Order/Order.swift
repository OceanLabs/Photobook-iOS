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

struct OrdersNotificationName {
    static let orderWasCreated = Notification.Name("ly.kite.sdk.orderWasCreated")
    static let orderWasSuccessful = Notification.Name("ly.kite.sdk.orderWasSuccessful")
}

class Order: Codable, Hashable {
    static func == (lhs: Order, rhs: Order) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    var deliveryDetails: OLDeliveryDetails?
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
    
    var countryCode: String {
        return deliveryDetails?.country.codeAlpha3 ?? Country.countryForCurrentLocale().codeAlpha3
    }

    func hash(into hasher: inout Hasher) {
        let country = deliveryDetails?.country ?? Country.countryForCurrentLocale()
        hasher.combine(country.codeAlpha3)
        
        if let promoCode = promoCode {
            hasher.combine(promoCode)
        }
        for product in products {
            hasher.combine(product.hash)
            hasher.combine(product.selectedShippingMethod?.id ?? 0)
        }
    }
    
    var hasCachedCost: Bool {
        return cachedCost != nil
    }
    
    var hasValidCachedCost: Bool {
        return cachedCost?.orderHash == hashValue
    }
    
    func updateCost(forceUpdate: Bool = false, forceShippingMethodUpdate: Bool = false, _ completionHandler: @escaping (_ error : APIClientError?) -> Void) {
        guard products.count != 0, !hasValidCachedCost || forceUpdate else {
            completionHandler(nil)
            return
        }
        
        let closure = {
            KiteAPIClient.shared.getCost(order: self) { [weak welf = self] result in
                guard let stelf = welf else { return }
                if case .failure(let error) = result {
                    if case .parsing(let details) = error {
                        OrderManager.shared.reset()
                        Analytics.shared.trackError(.parsing, details)
                        completionHandler(.generic)
                    } else {
                        completionHandler(error)
                    }
                    return
                }
                let cost = try! result.get()
                
                stelf.cachedCost = cost
                cost.orderHash = stelf.hashValue
                completionHandler(nil)
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
                closure()
            }
        } else {
            // Since we will update the cost, it means that we may have changed destination country, so check if the selected method is still valid.
            let countryCode = deliveryDetails?.country.codeAlpha3 ?? Country.countryForCurrentLocale().codeAlpha3
            for product in products {
                guard let availableShippingMethods = product.template.shippingMethodsFor(countryCode: countryCode) else {
                    product.selectedShippingMethod = nil
                    continue
                }
                
                let selectedMethodId = product.selectedShippingMethod?.id
                if selectedMethodId == nil || !availableShippingMethods.contains(where: { $0.id == selectedMethodId }) {
                    product.selectedShippingMethod = availableShippingMethods.first
                }
            }
            
            closure()
        }
    }
    
    func updateShippingMethods(_ completionHandler: @escaping (_ error: APIClientError?) -> Void) {
        KiteAPIClient.shared.getShippingInfo(for: OrderManager.shared.basketOrder.products.map({ $0.template.templateId })) { [weak welf = self] result in
            guard let stelf = welf else { return }
            
            if case .failure(let error) = result {
                if case .parsing(let details) = error {
                    Analytics.shared.trackError(.parsing, details)
                    completionHandler(.generic)
                } else {
                    completionHandler(error)
                }
                return
            }
            let shippingInfo = try! result.get()

            for product in stelf.products {
                guard let shippingInfoForProduct = shippingInfo[product.template.templateId] as? [String: Any] else { continue }

                product.template.countryToRegionMapping = shippingInfoForProduct["countryToRegionMapping"] as? [String: [String]]
                product.template.availableShippingMethods = shippingInfoForProduct["availableShippingMethods"] as? [String : [ShippingMethod]]
                
                if let shippingMethods = product.template.shippingMethodsFor(countryCode: stelf.countryCode) {
                    product.selectedShippingMethod = shippingMethods.first
                }
            }
            completionHandler(nil)
        }
    }

    func orderParameters() -> [String: Any]? {
        
        guard let finalTotalCost = cost?.total else { return nil }
        
        var parameters = [String: Any]()
        parameters["user_data"] = ["user_agent": KiteAPIClient.userAgent]
        
        parameters["shipping_address"] = deliveryDetails?.jsonRepresentation()
        
        var payment: [String: Any] = [
            "currency": finalTotalCost.currencyCode,
            "amount": finalTotalCost.value,
            "proof_of_payment": paymentToken ?? ""
        ]
        payment["promo_code"] = promoCode
        parameters["payment"] = payment
        
        parameters["customer"] = [
            "email": deliveryDetails?.email ?? "",
            "phone": deliveryDetails?.phone
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
        deliveryDetails = try values.decodeIfPresent(OLDeliveryDetails.self, forKey: .deliveryDetails)
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
        
        // Update hashValue as it is not guaranteed to be equal (refer to hashValue docs)
        if cachedCost != nil {
            cachedCost?.orderHash = hashValue
        }
    }
    
    func allAssets() -> [Asset] {
        return products.flatMap({ PhotobookAsset.assets(from: $0.assetsToUpload()) ?? [] })
    }
    
    func assetsToUpload() -> [Asset] {
        var assets = [Asset]()
        
        for product in products {
            let productAssets = PhotobookAsset.assets(from: product.assetsToUpload()) ?? []
            for asset in productAssets {
                if !assets.contains(where: { $0.identifier == asset.identifier }) {
                    assets.append(asset)
                }
            }
        }
        
        return assets
    }
    
    // MARK: Convenience methods

    func uploadedAssets() -> [Asset] {
        return assetsToUpload().filter({ $0.uploadUrl != nil })
    }

    func remainingAssetsToUpload() -> [Asset] {
        return assetsToUpload().filter({ $0.uploadUrl == nil })
    }
    
    func lineItem(for product: Product) -> LineItem? {
        return cost?.lineItems.first(where: { $0.identifier == product.identifier })
    }
}
