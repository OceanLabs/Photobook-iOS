//
//  PaymentAuthorizationManager.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 25/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Stripe
import PassKit

#if !COCOAPODS
import PayPalMobileSDK
#endif

enum PaymentMethod: Int, Codable {
    case creditCard, applePay, payPal
    
    var description: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .applePay: return "ApplePay"
        case .payPal: return "PayPal"
        }
    }
}

protocol PaymentAuthorizationManagerDelegate: class {
    func costUpdated()
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?)
    func modalPresentationDidFinish()
    func modalPresentationWillBegin()
}

protocol PaymentAPI {
    var supportsApplePay: Bool { get }
    func createToken(withCard card: Card, completion: @escaping (String?, Error?) -> ())
    func createToken(withPayment payment: PKPayment, completion: @escaping (String?, Error?) -> ())
    func applePayPaymentRequest(withMerchantId merchantId: String, country: String, currency: String) -> PKPaymentRequest
}

class PhotobookStripeAPI: PaymentAPI {
    
    var supportsApplePay: Bool {
        return Stripe.deviceSupportsApplePay()
    }
    
    func createToken(withCard card: Card, completion: @escaping (String?, Error?) -> ()) {
        
        let cardParams = STPCardParams()
        cardParams.number = card.number
        cardParams.expMonth = UInt(card.expireMonth)
        cardParams.expYear = UInt(card.expireYear)
        cardParams.cvc = card.cvv2

        STPAPIClient.shared().createToken(withCard: cardParams) { (token, error) in
            completion(token?.tokenId, error)
        }
    }
    
    func createToken(withPayment payment: PKPayment, completion: @escaping (String?, Error?) -> ()) {
        STPAPIClient.shared().createToken(with: payment) { (token, error) in
            completion(token?.tokenId, error)
        }
    }
    
    func applePayPaymentRequest(withMerchantId merchantId: String, country: String, currency: String) -> PKPaymentRequest {
        return Stripe.paymentRequest(withMerchantIdentifier: merchantId, country: country, currency: currency)
    }
}


class PaymentAuthorizationManager: NSObject {
    
    static var applePayPayTo: String = {
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return "Kite.ly (via \(appName))"
        }
        return "Kite.ly"
    }()
    static var applePayMerchantId: String!
    
    lazy var paymentApi: PaymentAPI = PhotobookStripeAPI()
    lazy var basketOrder: Order = OrderManager.shared.basketOrder
    
    weak var delegate: (PaymentAuthorizationManagerDelegate & UIViewController)?
    
    static var isApplePayAvailable: Bool {
        return Stripe.deviceSupportsApplePay() && PaymentAuthorizationManager.applePayMerchantId != nil
    }
    
    func authorizePayment(cost: Cost, method: PaymentMethod){
        switch method {
        case .applePay:
            authorizeApplePay(cost: cost)
        case .payPal:
            authorizePayPal(cost: cost)
        case .creditCard:
            authorizeCreditCard(cost: cost)
        }
    }
    
    /// Ask Stripe for a charge authorization token
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizeCreditCard(cost: Cost) {
        guard let currentCard = Card.currentCard else { return }
        
        paymentApi.createToken(withCard: currentCard) { [weak welf = self] (tokenId, error) in
            welf?.delegate?.paymentAuthorizationDidFinish(token: nil, error: error, completionHandler: nil)
        }
    }
    
    /// Present the Apple Pay authorization sheet
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizeApplePay(cost: Cost) {
        guard let applePayMerchantId = PaymentAuthorizationManager.applePayMerchantId else {
            fatalError("Missing merchant ID for ApplePay: PhotobookSDK.shared.applePayMerchantID")
        }

        let paymentRequest = paymentApi.applePayPaymentRequest(withMerchantId: applePayMerchantId, country: "US", currency: basketOrder.currencyCode)
        
        paymentRequest.paymentSummaryItems = summaryItemsForApplePay(cost: cost, shippingMethodId: basketOrder.shippingMethod!)
        paymentRequest.requiredShippingAddressFields = [.postalAddress, .name, .email, .phone]
        
        guard let paymentController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else { return }
        paymentController.delegate = self
        
        delegate?.modalPresentationWillBegin()
        delegate?.present(paymentController, animated: true, completion: nil)
    }
    
    
    /// Present the PayPal login view controller
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizePayPal(cost: Cost) {
        guard let totalCost = cost.shippingMethod(id: basketOrder.shippingMethod)?.totalCostRounded,
              let details = basketOrder.deliveryDetails, details.isValid,
              let orderDescription = basketOrder.orderDescription else {
                return
        }
        
        let address = details.address!
        
        let paypalAddress = PayPalShippingAddress(recipientName: details.fullName!, withLine1: address.line1!, withLine2: address.line2 ?? "", withCity: address.city!, withState: address.stateOrCounty ?? "", withPostalCode: address.zipOrPostcode!, withCountryCode: address.country.codeAlpha2)
        
        let payment = PayPalPayment(amount: totalCost as NSDecimalNumber, currencyCode: basketOrder.currencyCode, shortDescription: orderDescription, intent: .authorize)
        payment.shippingAddress = paypalAddress

        let config = PayPalConfiguration()
        config.acceptCreditCards = false
        config.payPalShippingAddressOption = .provided

        guard let paymentController = PayPalPaymentViewController(payment: payment, configuration: config, delegate: self) else { return }
        delegate?.modalPresentationWillBegin()
        delegate?.present(paymentController, animated: true, completion: nil)
    }
}

//// MARK: - PayPalPaymentDelegate
//
extension PaymentAuthorizationManager: PayPalPaymentDelegate {

    func payPalPaymentDidCancel(_ paymentViewController: PayPalPaymentViewController) {
        paymentViewController.dismiss(animated: true, completion: nil)
    }

    func payPalPaymentViewController(_ paymentViewController: PayPalPaymentViewController, didComplete completedPayment: PayPalPayment) {
        paymentViewController.dismiss(animated: true, completion: {
            guard let confirmation = completedPayment.confirmation as? [String: Any] else { return }
            guard let response = confirmation["response"] as? [String: Any] else { return }
            guard let token = response["id"] as? String else { return }

            let index = token.index(token.startIndex, offsetBy: 3)
            self.delegate?.paymentAuthorizationDidFinish(token: "PAUTH\(token[index...])", error: nil, completionHandler: nil)
        })
    }
}

extension PaymentAuthorizationManager: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        let shippingAddress = Address()
        shippingAddress.line1 = payment.shippingContact?.postalAddress?.street
        shippingAddress.city = payment.shippingContact?.postalAddress?.city
        shippingAddress.stateOrCounty = payment.shippingContact?.postalAddress?.state
        shippingAddress.zipOrPostcode = payment.shippingContact?.postalAddress?.postalCode

        let deliveryDetails = DeliveryDetails()
        deliveryDetails.address = shippingAddress
        deliveryDetails.firstName = payment.shippingContact?.name?.givenName
        deliveryDetails.lastName = payment.shippingContact?.name?.familyName
        deliveryDetails.email = payment.shippingContact?.emailAddress
        deliveryDetails.phone = payment.shippingContact?.phoneNumber?.stringValue

        if let code = payment.shippingContact?.postalAddress?.isoCountryCode, let country = Country.countryFor(code: code) {
            shippingAddress.country = country
        } else if let name = payment.shippingContact?.postalAddress?.country, let country = Country.countryFor(name: name) {
            shippingAddress.country = country
        }
        
        guard shippingAddress.isValid else {
            completion(.invalidShippingPostalAddress)
            return
        }
        
        guard let emailAddress = payment.shippingContact?.emailAddress, emailAddress.isValidEmailAddress() else {
            completion(.invalidShippingContact)
            return
        }
        
        basketOrder.deliveryDetails = deliveryDetails
        
        paymentApi.createToken(withPayment: payment) { [weak welf = self] (tokenId, error) in
            guard error == nil else {
                completion(.failure)
                return
            }
            
            welf?.delegate?.paymentAuthorizationDidFinish(token: tokenId, error: nil, completionHandler: completion)
            completion(.success)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: {
            self.delegate?.modalPresentationDidFinish()
        })
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelectShippingContact contact: PKContact, completion: @escaping (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        
        let shippingAddress = Address()
        
        if let code = contact.postalAddress?.isoCountryCode, let country = Country.countryFor(code: code){
            shippingAddress.country = country
        }
        
        let deliveryDetails = DeliveryDetails()
        deliveryDetails.address = shippingAddress
        basketOrder.deliveryDetails = deliveryDetails
        
        basketOrder.updateCost { [weak welf = self] (error: Error?) in
            
            guard let stelf = welf, let cachedCost = stelf.basketOrder.cachedCost else {
                completion(.failure, [PKShippingMethod](), [PKPaymentSummaryItem]())
                return
            }

            guard error == nil else {
                completion(.failure, [PKShippingMethod](), stelf.summaryItemsForApplePay(cost: cachedCost, shippingMethodId: stelf.basketOrder.shippingMethod!))
                return
            }

            //Cost is expected to change here so update views
            stelf.delegate?.costUpdated()
            
            completion(.success, [PKShippingMethod](), stelf.summaryItemsForApplePay(cost: cachedCost, shippingMethodId: stelf.basketOrder.shippingMethod!))
        }
    }
    
    private func summaryItemsForApplePay(cost: Cost?, shippingMethodId: Int) -> [PKPaymentSummaryItem] {
        guard
            let lineItems = cost?.lineItems, lineItems.count > 0,
            let totalCost = cost?.shippingMethod(id: shippingMethodId)?.totalCost as NSDecimalNumber?
        else {
            return [PKPaymentSummaryItem]()
        }
        
        var summaryItems = lineItems.map { return PKPaymentSummaryItem(label: $0.name, amount: $0.cost as NSDecimalNumber) }
        summaryItems.append(PKPaymentSummaryItem(label: PaymentAuthorizationManager.applePayPayTo, amount: totalCost))
        
        return summaryItems
    }
}
