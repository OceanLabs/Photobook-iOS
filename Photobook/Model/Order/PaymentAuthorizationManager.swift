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
import KeychainSwift
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

struct PaymentNotificationName {
    static let authorized = Notification.Name("ly.kite.photobook.sdk.paymentAuthorizedNotificationName")
}

protocol PaymentAuthorizationManagerDelegate: class {
    func costUpdated()
    func paymentAuthorizationManagerDidUpdateDetails()
    func paymentAuthorizationRequiresAction(withContext context: STPRedirectContext)
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
    
    private static var paypalApiKey: String? {
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
    
    private static var stripeKey: String? {
        didSet {
            guard let stripeKey = stripeKey else {
                return
            }
            Stripe.setDefaultPublishableKey(stripeKey)
        }
    }
    
    static var hasSetPaymentKeys: Bool {
        return paypalApiKey != nil || stripeKey != nil
    }
    
    static var shouldUpdatePaymentKeys = true {
        didSet { KiteAPIClient.shared.stripeCustomerId = nil }
    }
    
    weak var delegate: (PaymentAuthorizationManagerDelegate & UIViewController)?
    
    var availablePaymentMethods: [PaymentMethod] {
        var methods = [PaymentMethod]()
        
        // Apple Pay
        if PaymentAuthorizationManager.isApplePayAvailable { methods.append(.applePay) }
        
        // PayPal
        if PaymentAuthorizationManager.isPayPalAvailable { methods.append(.payPal) }
        
        if selectedPaymentOption() != nil { methods.append(.creditCard) }
        
        methods.append(.creditCard) // Adding a new card is always available
        
        return methods
    }
    
    static var isApplePayAvailable: Bool {
        return Stripe.deviceSupportsApplePay() && applePayMerchantId != nil
    }
    
    static var isPayPalAvailable: Bool {
        return NSClassFromString("PayPalMobile") != nil
    }
    
    private static func setPaymentKeys(_ completionHandler: ((_ error: APIClientError?) -> Void)? = nil) {
        guard !hasSetPaymentKeys || shouldUpdatePaymentKeys else {
            completionHandler?(nil)
            return
        }

        KiteAPIClient.shared.getPaymentKeys() { result in
            if case .failure(let error) = result {
                completionHandler?(error)
                return
            }
            let keys = try! result.get()
            
            self.paypalApiKey = keys.paypalKey
            self.stripeKey = keys.stripeKey
            PaymentAuthorizationManager.shouldUpdatePaymentKeys = false
            
            completionHandler?(nil)
        }
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

    private var customerContext = STPCustomerContext(keyProvider: KiteAPIClient.shared)

    var stripeHostViewController: UIViewController? {
        didSet {
            guard let stripeHostViewController = stripeHostViewController, stripePaymentContext?.hostViewController != stripeHostViewController else {
                delegate?.paymentAuthorizationManagerDidUpdateDetails()
                return
            }
            setStripePaymentContext(with: stripeHostViewController)
        }
    }

    private func setStripePaymentContext(with hostViewController: UIViewController) {
        func configure(with stripeKey: String) {
            let config = STPPaymentConfiguration.shared()
            
            config.publishableKey = stripeKey
            config.companyName = PaymentAuthorizationManager.applePayPayTo
            config.requiredBillingAddressFields = .none
            config.requiredShippingAddressFields = nil
            config.canDeletePaymentOptions = true
            
            let paymentContext = STPPaymentContext(customerContext: customerContext,
                                                   configuration: config,
                                                   theme: .default())
            paymentContext.prefilledInformation = STPUserInformation()
            paymentContext.hostViewController = hostViewController
            paymentContext.defaultPaymentMethod = selectedPaymentOptionStripeId()
            paymentContext.delegate = self
            stripePaymentContext = paymentContext
        }
                
        PaymentAuthorizationManager.setPaymentKeys() { error in
            guard let stripePublicKey = PaymentAuthorizationManager.stripeKey else { return }
            configure(with: stripePublicKey)
        }
    }
    
    func isPaymentAuthorized(withClientSecret clientSecret: String, completionHandler: @escaping (_ authorized: Bool) -> Void) {
        STPAPIClient.shared().retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, error in
            guard error == nil else {
                completionHandler(false)
                return
            }
            
            // The payment intent should have a status of "requires capture" for the app to proceed and finalise the order
            // Any other status is assumed a failure to authorise. Stripe hinted at a charges array having information about the error
            // but it is not available through the iOS API
            if let paymentIntent = paymentIntent, paymentIntent.status == .requiresCapture {
                completionHandler(true)
                return
            }
            completionHandler(false)
        }
    }
    
    func selectedPaymentOptionStripeId() -> String? {
        return (selectedPaymentOption() as? STPPaymentMethod)?.stripeId
    }
    
    func selectedPaymentOption() -> STPPaymentOption? {
        if let paymentOption = stripePaymentContext?.selectedPaymentOption { return paymentOption }
        
        let (paymentMethod, stripeId) = SelectedPaymentMethodHandler.load()
        if paymentMethod == .creditCard, let stripeId = stripeId {
            if stripePaymentContext?.defaultPaymentMethod != stripeId {
                stripePaymentContext?.defaultPaymentMethod = stripeId
            }
            return stripePaymentContext?.paymentOptions?.first { ($0 as? STPPaymentMethod)?.stripeId == stripeId }
        }

        return nil
    }
    
    /// Ask Stripe for a charge authorization token
    ///
    /// - Parameter cost: The total cost of the order
    private func authorizeCreditCard(cost: Cost) {
        createPaymentIntent(withCost: cost)
    }
    
    private func createPaymentIntent(withCost cost: Cost) {
        var sourceId = (selectedPaymentOption() as? STPPaymentMethod)?.stripeId
        if sourceId == nil {
            // In some rare scenarios the context seems to be setting initialising and missing the payment options
            // However the default payment method will be set by selectedPaymentOption()
            sourceId = stripePaymentContext?.defaultPaymentMethod
        }
        
        guard sourceId != nil else { return }
    
        let amount = Double(cost.total.int()) / 100.0
        let currency = cost.total.currencyCode
        
        KiteAPIClient.shared.createPaymentIntentWithSourceId(sourceId!, amount: amount, currency: currency) { [weak welf = self] result in
            guard let stelf = welf else { return }
            
            if case .failure(let error) = result {
                stelf.delegate?.paymentAuthorizationDidFinish(token: nil, error: error, completionHandler: nil)
                return
            }
            let paymentIntent = try! result.get()
            
            if paymentIntent.status == .requiresAction {
                guard let redirectContext = STPRedirectContext(paymentIntent: paymentIntent, completion: { _, _ in }) else {
                    let error = APIClientError.parsing(details: "PaymentResult: Failed to redirect to authorization page")
                    stelf.delegate?.paymentAuthorizationDidFinish(token: nil, error: error, completionHandler: nil)
                    return
                }
                stelf.delegate?.paymentAuthorizationRequiresAction(withContext: redirectContext)
            } else {
                stelf.delegate?.paymentAuthorizationDidFinish(token: paymentIntent.stripeId, error: nil, completionHandler: nil)
            }
        }
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

        let deliveryDetails = OLDeliveryDetails()
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
        
        let deliveryDetails = OLDeliveryDetails()
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

            // Cost is expected to change here so update views
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
        if stripePaymentContext?.selectedPaymentOption != nil && basketOrder.paymentMethod == nil {
            basketOrder.paymentMethod = .creditCard
        }
        delegate?.paymentAuthorizationManagerDidUpdateDetails()
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        delegate?.paymentAuthorizationDidFinish(token: nil, error: error, completionHandler: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {}
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {}
}

/// Saves the payment method selected by the user
/// For bank cards, it also saves the stripeId in case the user adds multiple ones.
class SelectedPaymentMethodHandler {
    
    private struct StorageKeys {
        static var live = "SelectedPaymentMethodLive"
        static var test = "SelectedPaymentMethodTest"
    }
    
    private static var storageKey: String {
        return APIClient.environment == .live ? StorageKeys.live : StorageKeys.test
    }
    
    static func save(_ paymentMethod: PaymentMethod, id: String? = nil) {
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") { return }
        let value = "\(paymentMethod.rawValue)" + (id != nil ? ":" + id! : "")
        KeychainSwift().set(value, forKey: storageKey)
    }
    
    static func load() -> (PaymentMethod, String?) {
        if ProcessInfo.processInfo.arguments.contains("UITESTINGENVIRONMENT") { return (.applePay, nil) }
        if let value = KeychainSwift().get(storageKey) {
            let components = value.components(separatedBy: ":")
            return (PaymentMethod(rawValue: Int(components.first!)!)!, components.count > 1 ? components[1] : nil)
        }
        return (.applePay, nil)
    }
}
