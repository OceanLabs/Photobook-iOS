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
import Stripe
import PassKit
import PayPalDynamicLoader

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
    func paymentAuthorizationManagerDidUpdateDetails()
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?)
    func modalPresentationDidFinish()
    func modalPresentationWillBegin()
}

protocol PaymentAPI {
    var supportsApplePay: Bool { get }
    func createToken(withPayment payment: PKPayment, completion: @escaping (String?, Error?) -> ())
    func applePayPaymentRequest(withMerchantId merchantId: String, country: String, currency: String) -> PKPaymentRequest
}

class PhotobookStripeAPI: PaymentAPI {
    
    var supportsApplePay: Bool {
        return Stripe.deviceSupportsApplePay()
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
    
    var stripePaymentContext: STPPaymentContext?
    
    static var paypalApiKey: String? {
        didSet {
            guard OLPayPalWrapper.isPayPalAvailable(),
                let paypalApiKey = paypalApiKey else {
                    return
            }
            switch KiteAPIClient.environment {
            case .test:
                OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["sandbox" : paypalApiKey])
                OLPayPalWrapper.preconnect(withEnvironment: "sandbox") /*PayPalEnvironmentSandbox*/
            case .live:
                OLPayPalWrapper.initializeWithClientIds(forEnvironments: ["live" : paypalApiKey])
                OLPayPalWrapper.preconnect(withEnvironment: "live") /*PayPalEnvironmentProduction*/
            }
        }
    }
    
    static var stripeKey: String? {
        didSet {
            guard let stripeKey = stripeKey else {
                return
            }
            Stripe.setDefaultPublishableKey(stripeKey)
        }
    }
    
    static var haveSetPaymentKeys: Bool {
        return paypalApiKey != nil || stripeKey != nil
    }
    
    weak var delegate: (PaymentAuthorizationManagerDelegate & UIViewController)?
    
    var availablePaymentMethods: [PaymentMethod] {
        var methods = [PaymentMethod]()
        
        // Apple Pay
        if PaymentAuthorizationManager.isApplePayAvailable {
            methods.append(.applePay)
        }
        
        // PayPal
        if PaymentAuthorizationManager.isPayPalAvailable {
            methods.append(.payPal)
        }
        
        if stripePaymentContext?.selectedPaymentMethod != nil {
            methods.append(.creditCard)
        }
        
        methods.append(.creditCard) // Adding a new card is always available
        
        return methods
    }
    
    static var isApplePayAvailable: Bool {
        return Stripe.deviceSupportsApplePay() && applePayMerchantId != nil
    }
    
    static var isPayPalAvailable: Bool {
        return NSClassFromString("PayPalMobile") != nil
    }
    
    func authorizePayment(cost: Cost, method: PaymentMethod) {
        switch method {
        case .applePay:
            authorizeApplePay(cost: cost)
        case .payPal:
            authorizePayPal(cost: cost)
        case .creditCard:
            authorizeCreditCard(cost: cost)
        }
    }

    func setupStripePaymentContext() {
        let config = STPPaymentConfiguration.shared()
        guard let stripePublicKey = PaymentAuthorizationManager.stripeKey else { return }
        
        config.publishableKey = stripePublicKey
        config.companyName = PaymentAuthorizationManager.applePayPayTo
        config.requiredBillingAddressFields = .none
        config.requiredShippingAddressFields = [.postalAddress, .phoneNumber]
        config.canDeletePaymentMethods = true

        let customerContext = STPCustomerContext(keyProvider: KiteAPIClient.shared)
        let paymentContext = STPPaymentContext(customerContext: customerContext,
                                               configuration: config,
                                               theme: .default())
        paymentContext.prefilledInformation = STPUserInformation()
        paymentContext.delegate = self
        stripePaymentContext = paymentContext
    }
    
    /// Ask Stripe for a charge authorization token
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizeCreditCard(cost: Cost) {
        guard let paymentContext = stripePaymentContext else { return }

        paymentContext.paymentCurrency = cost.total.currencyCode
        paymentContext.paymentAmount = cost.total.int()
        paymentContext.requestPayment()
    }
    
    /// Present the Apple Pay authorization sheet
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizeApplePay(cost: Cost) {
        guard let applePayMerchantId = PaymentAuthorizationManager.applePayMerchantId else {
            fatalError("Missing merchant ID for ApplePay: PhotobookSDK.shared.applePayMerchantID")
        }

        let paymentRequest = paymentApi.applePayPaymentRequest(withMerchantId: applePayMerchantId, country: "US", currency: cost.total.currencyCode)
        
        paymentRequest.paymentSummaryItems = summaryItemsForApplePay(cost: cost)
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
        let totalCost = cost.total.value
        guard let details = basketOrder.deliveryDetails, details.isValid,
            let orderDescription = basketOrder.orderDescription
            else {
                return
        }
        
        let paypalAddress = OLPayPalWrapper.payPalShippingAddress(withRecipientName: details.fullName, withLine1: details.line1, withLine2: details.line2, withCity: details.city, withState: details.stateOrCounty, withPostalCode: details.zipOrPostcode, withCountryCode: details.country.codeAlpha2)

        let payment = OLPayPalWrapper.payPalPayment(withAmount: totalCost as NSDecimalNumber, currencyCode: cost.total.currencyCode, shortDescription: orderDescription, intent: 1/*PayPalPaymentIntentAuthorize*/, shippingAddress: paypalAddress)

        let config = OLPayPalWrapper.payPalConfiguration(withShippingAddressOption: 1/*PayPalShippingAddressOptionProvided*/, acceptCreditCards: false)

        guard let paymentController = OLPayPalWrapper.payPalPaymentViewController(withPayment: payment, configuration: config, delegate: self) as? UIViewController else { return }
        delegate?.modalPresentationWillBegin()
        delegate?.present(paymentController, animated: true, completion: nil)
    }
}

// MARK: - PayPalPaymentDelegate

extension PaymentAuthorizationManager {

    @objc func payPalPaymentDidCancel(_ paymentViewController: UIViewController) {
        paymentViewController.dismiss(animated: true, completion: nil)
    }

    @objc func payPalPaymentViewController(_ paymentViewController: UIViewController, didCompletePayment completedPayment: Any) {
        paymentViewController.dismiss(animated: true, completion: {
            guard let confirmation = OLPayPalWrapper.confirmation(withPayment: completedPayment) as? [String: Any] else { return }
            guard let response = confirmation["response"] as? [String: Any] else { return }
            guard let token = response["id"] as? String else { return }

            let index = token.index(token.startIndex, offsetBy: 3)
            self.delegate?.paymentAuthorizationDidFinish(token: "PAUTH\(token[index...])", error: nil, completionHandler: nil)
        })
    }
}

extension PaymentAuthorizationManager: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {

        let deliveryDetails = DeliveryDetails()
        deliveryDetails.firstName = payment.shippingContact?.name?.givenName
        deliveryDetails.lastName = payment.shippingContact?.name?.familyName
        deliveryDetails.email = payment.shippingContact?.emailAddress
        deliveryDetails.phone = payment.shippingContact?.phoneNumber?.stringValue
        deliveryDetails.line1 = payment.shippingContact?.postalAddress?.street
        deliveryDetails.city = payment.shippingContact?.postalAddress?.city
        deliveryDetails.stateOrCounty = payment.shippingContact?.postalAddress?.state
        deliveryDetails.zipOrPostcode = payment.shippingContact?.postalAddress?.postalCode


        if let code = payment.shippingContact?.postalAddress?.isoCountryCode, let country = Country.countryFor(code: code) {
            deliveryDetails.country = country
        } else if let name = payment.shippingContact?.postalAddress?.country, let country = Country.countryFor(name: name) {
            deliveryDetails.country = country
        }
        
        guard let emailAddress = payment.shippingContact?.emailAddress, emailAddress.isValidEmailAddress() else {
            completion(.invalidShippingContact)
            return
        }
        
        guard deliveryDetails.isValid else {
            completion(.invalidShippingPostalAddress)
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
        
        let deliveryDetails = DeliveryDetails()
        if let code = contact.postalAddress?.isoCountryCode, let country = Country.countryFor(code: code){
            deliveryDetails.country = country
        }
        basketOrder.deliveryDetails = deliveryDetails
        
        basketOrder.updateCost { [weak welf = self] (error: Error?) in
            
            guard let stelf = welf, let cost = stelf.basketOrder.cost else {
                completion(.failure, [PKShippingMethod](), [PKPaymentSummaryItem]())
                return
            }

            guard error == nil, let applePaySummary = welf?.summaryItemsForApplePay(cost: cost) else {
                completion(.failure, [PKShippingMethod](), [PKPaymentSummaryItem]())
                return
            }

            //Cost is expected to change here so update views
            stelf.delegate?.costUpdated()
            
            completion(.success, [PKShippingMethod](), applePaySummary)
        }
    }
    
    private func summaryItemsForApplePay(cost: Cost?) -> [PKPaymentSummaryItem] {
        guard
            let lineItems = cost?.lineItems, lineItems.count > 0,
            let shippingCost = cost?.totalShippingPrice,
            let totalCost = cost?.total.value as NSDecimalNumber?
        else {
            return [PKPaymentSummaryItem]()
        }
        
        var summaryItems = lineItems.map { return PKPaymentSummaryItem(label: $0.name, amount: $0.price.value as NSDecimalNumber) }
        summaryItems.append(PKPaymentSummaryItem(label: CommonLocalizedStrings.shipping, amount: shippingCost.value as NSDecimalNumber))
        summaryItems.append(PKPaymentSummaryItem(label: PaymentAuthorizationManager.applePayPayTo, amount: totalCost))
        
        return summaryItems
    }

}

extension PaymentAuthorizationManager: STPPaymentContextDelegate {
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        if stripePaymentContext?.selectedPaymentMethod != nil {
            basketOrder.paymentMethod = .creditCard
        }
        delegate?.paymentAuthorizationManagerDidUpdateDetails()
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        delegate?.paymentAuthorizationDidFinish(token: nil, error: error, completionHandler: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        delegate?.paymentAuthorizationDidFinish(token: paymentResult.source.stripeID, error: nil, completionHandler: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {}
}

