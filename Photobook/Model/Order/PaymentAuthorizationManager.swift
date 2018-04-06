//
//  PaymentAuthorizationManager.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 25/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Stripe

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

class PaymentAuthorizationManager: NSObject {
    
    private struct Constants {
        static let applePayPayTo = "Canon"
        static let applePayMerchantId = "merchant.ly.kite.sdk"
        
        static let stripePublicKey = PhotobookManager.environment == .test ? "pk_test_fJtOj7oxBKrLFOneBFLj0OH3" : "pk_live_qQhXxzjS8inja3K31GDajdXo"
    }
    
    weak var delegate : (PaymentAuthorizationManagerDelegate & UIViewController)?
    
    var applePayPayTo: String {
        get{
            return Constants.applePayPayTo
        }
    }
    var applePayMerchantId: String {
        get{
            return Constants.applePayMerchantId
        }
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
        let stripeKey = Constants.stripePublicKey
        guard var currentCard = Card.currentCard else { return }
        
        currentCard.clientId = stripeKey
        currentCard.authorise() { (error, token) in
            guard let token = token, error == nil else {
                self.delegate?.paymentAuthorizationDidFinish(token: nil, error: error, completionHandler: nil)
                return
            }
            
            self.delegate?.paymentAuthorizationDidFinish(token: token, error: nil, completionHandler: nil)
        }
    }
    
    /// Present the Apple Pay authorization sheet
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizeApplePay(cost: Cost) {
        let paymentRequest = Stripe.paymentRequest(withMerchantIdentifier: applePayMerchantId, country: "US", currency: OrderManager.basketOrder.currencyCode)
        
        paymentRequest.paymentSummaryItems = cost.summaryItemsForApplePay(payTo: applePayPayTo, shippingMethodId: OrderManager.basketOrder.shippingMethod!)
        paymentRequest.requiredShippingAddressFields = [.postalAddress, .name, .email, .phone]
        
        guard let paymentController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else { return }
        paymentController.delegate = self
        
        delegate?.modalPresentationWillBegin()
        delegate?.present(paymentController, animated: true, completion: nil)
    }
    
    
    /// Present the PayPal login view controller
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizePayPal(cost: Cost){
        let details = OrderManager.basketOrder.deliveryDetails
        let address = details?.address

        guard let totalCost = cost.shippingMethod(id: OrderManager.basketOrder.shippingMethod)?.totalCost,
            let firstName = details?.firstName,
            let lastName = details?.lastName,
            let line1 = address?.line1,
            let city = address?.city,
            let postalCode = address?.zipOrPostcode,
            let country = address?.country,
            let product = ProductManager.shared.product
            else { return }

        let paypalAddress = PayPalShippingAddress(recipientName: String(format: "%@ %@", firstName, lastName), withLine1: line1, withLine2: address?.line2 ?? "", withCity: city, withState: address?.stateOrCounty ?? "", withPostalCode: postalCode, withCountryCode: country.codeAlpha2)
        let payment = PayPalPayment(amount: totalCost as NSDecimalNumber, currencyCode: OrderManager.basketOrder.currencyCode, shortDescription: product.name, intent: .authorize)
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
extension PaymentAuthorizationManager: PayPalPaymentDelegate{

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

extension PaymentAuthorizationManager: PKPaymentAuthorizationViewControllerDelegate{
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        let shippingAddress = Address()
        let deliveryDetails = DeliveryDetails()
        deliveryDetails.address = shippingAddress
        deliveryDetails.firstName = payment.shippingContact?.name?.givenName
        deliveryDetails.lastName = payment.shippingContact?.name?.familyName
        shippingAddress.line1 = payment.shippingContact?.postalAddress?.street
        shippingAddress.city = payment.shippingContact?.postalAddress?.city
        shippingAddress.stateOrCounty = payment.shippingContact?.postalAddress?.state
        shippingAddress.zipOrPostcode = payment.shippingContact?.postalAddress?.postalCode
        if let code = payment.shippingContact?.postalAddress?.isoCountryCode, let country = Country.countryFor(code: code){
            shippingAddress.country = country
        }
        else if let name = payment.shippingContact?.postalAddress?.country, let country = Country.countryFor(name: name){
            shippingAddress.country = country
        }
        
        deliveryDetails.email = payment.shippingContact?.emailAddress
        deliveryDetails.phone = payment.shippingContact?.phoneNumber?.stringValue
        
        guard shippingAddress.isValid else{
            completion(.invalidShippingPostalAddress)
            return
        }
        
        guard let emailAddress = payment.shippingContact?.emailAddress, emailAddress.isValidEmailAddress() else {
            completion(.invalidShippingContact)
            return
        }
        
        deliveryDetails.email = payment.shippingContact?.emailAddress
        deliveryDetails.phone = payment.shippingContact?.phoneNumber?.stringValue
        OrderManager.basketOrder.deliveryDetails = deliveryDetails
        
        let client = STPAPIClient(publishableKey: Constants.stripePublicKey)
        client.createToken(with: payment, completion: {(token: STPToken?, error: Error?) in
            guard error == nil else{
                completion(.failure)
                return
            }
            
            self.delegate?.paymentAuthorizationDidFinish(token: token?.tokenId, error: nil, completionHandler: completion)
            completion(.success)
        })
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
        OrderManager.basketOrder.deliveryDetails = deliveryDetails
        
        OrderManager.basketOrder.updateCost { [weak welf = self] (error: Error?) in
            
            guard let cachedCost = OrderManager.basketOrder.cachedCost else {
                completion(.failure, [PKShippingMethod](), [PKPaymentSummaryItem]())
                return
            }

            guard error == nil else {
                completion(.failure, [PKShippingMethod](), cachedCost.summaryItemsForApplePay(payTo: welf!.applePayPayTo, shippingMethodId: OrderManager.basketOrder.shippingMethod!))
                return
            }

            //Cost is expected to change here so update views
            welf?.delegate?.costUpdated()
            
            completion(.success, [PKShippingMethod](), cachedCost.summaryItemsForApplePay(payTo: welf!.applePayPayTo, shippingMethodId: OrderManager.basketOrder.shippingMethod!))
        }
    }
}
