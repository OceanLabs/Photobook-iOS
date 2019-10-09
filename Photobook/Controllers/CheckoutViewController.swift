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
import PassKit
import Stripe

class CheckoutViewController: UIViewController {
    
    private struct Constants {
        static let receiptSegueName = "ReceiptSegue"
        
        static let segueIdentifierDeliveryDetails = "segueDeliveryDetails"
        static let segueIdentifierShippingMethods = "segueShippingMethods"
        static let segueIdentifierPaymentMethods = "seguePaymentMethods"
        static let segueIdentifierAddressInput = "segueAddressInput"
        
        static let detailsLabelColor = UIColor.black
        static let detailsLabelColorRequired = UIColor.red.withAlphaComponent(0.6)
        
        static let smallDeviceScreenWidth: CGFloat = 320.0
        static let smallDeviceTableViewCellHeight: CGFloat = 100.0
        static let largeDeviceTableViewCellHeight: CGFloat = 130.0
        
        static let loadingDetailsText = NSLocalizedString("Controllers/CheckoutViewController/EmptyScreenLoadingText",
                                                    value: "Loading price details",
                                                    comment: "Info text displayed next to a loading indicator while loading price details")
        static let loadingPaymentText = NSLocalizedString("Controllers/CheckoutViewController/PaymentLoadingText",
                                                   value: "Preparing Payment",
                                                   comment: "Info text displayed while preparing for payment service")
        static let processingText = NSLocalizedString("Controllers/CheckoutViewController/ProcessingText",
                                                          value: "Processing",
                                                          comment: "Info text displayed while processing the order")
        static let submittingOrderText = NSLocalizedString("Controllers/CheckoutViewController/SubmittingOrderText",
                                                          value: "Submitting Order",
                                                          comment: "Info text displayed while submitting order")
        static let labelRequiredText = NSLocalizedString("Controllers/CheckoutViewController/LabelRequiredText",
                                                          value: "Required",
                                                          comment: "Hint on empty but required order text fields if user clicks on pay")
        static let payingWithText = NSLocalizedString("Controllers/CheckoutViewController/PaymentMethodText",
                                                         value: "Paying With",
                                                         comment: "Left side of payment method row if a payment method is selected")
        static let paymentMethodText = NSLocalizedString("Controllers/CheckoutViewController/PaymentMethodRequiredText",
                                                                 value: "Payment Method",
                                                                 comment: "Left side of payment method row if required hint is displayed")
        static let promoCodePlaceholderText = NSLocalizedString("Controllers/CheckoutViewController/PromoCodePlaceholderText",
                                                         value: "Add here",
                                                         comment: "Placeholder text for promo code")
        static let title = NSLocalizedString("Controllers/CheckoutViewController/Title", value: "Payment", comment: "Payment screen title")
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var promoCodeActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var promoCodeLabel: UILabel! { didSet { promoCodeLabel.scaleFont() } }
    @IBOutlet private weak var promoCodeView: UIView!
    @IBOutlet private weak var promoCodeTextField: UITextField! { didSet { promoCodeTextField.scaleFont() } }
    @IBOutlet private weak var promoCodeClearButton: UIButton!
    @IBOutlet private weak var deliveryDetailsView: UIView!
    @IBOutlet private weak var deliveryDetailsLabel: UILabel! { didSet { deliveryDetailsLabel.scaleFont() } }
    @IBOutlet private weak var shippingMethodView: UIView!
    @IBOutlet private weak var shippingMethodLabel: UILabel! { didSet { shippingMethodLabel.scaleFont() } }
    @IBOutlet private weak var paymentMethodView: UIView!
    @IBOutlet private weak var paymentMethodTitleLabel: UILabel! { didSet { paymentMethodTitleLabel.scaleFont() } }
    @IBOutlet private weak var paymentMethodLabel: UILabel! { didSet { paymentMethodLabel.scaleFont() } }
    @IBOutlet private weak var paymentMethodIconImageView: UIImageView!
    @IBOutlet private weak var payButtonContainerView: UIView!
    @IBOutlet private weak var payButton: UIButton! { didSet { payButton.titleLabel?.scaleFont() } }
    @IBOutlet private weak var infoLabelDeliveryDetails: UILabel! { didSet { infoLabelDeliveryDetails.scaleFont() } }
    @IBOutlet private weak var infoLabelShipping: UILabel! { didSet { infoLabelShipping.scaleFont() } }
    
    private var applePayButton: PKPaymentButton?
    private var payButtonOriginalColor: UIColor!

    @IBOutlet var promoCodeDismissGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet private weak var hideDeliveryDetailsConstraint: NSLayoutConstraint!
    @IBOutlet private weak var showDeliveryDetailsConstraint: NSLayoutConstraint!
    @IBOutlet private weak var optionsViewBottomContraint: NSLayoutConstraint!
    @IBOutlet private weak var optionsViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var promoCodeViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var promoCodeAccessoryConstraint: NSLayoutConstraint!
    @IBOutlet private weak var promoCodeNormalConstraint: NSLayoutConstraint!
    
    private var previousPromoText: String? // Stores previously entered promo string to determine if it has changed
    private var editingProductIndex: Int?
    
    private var modalPresentationDismissedGroup = DispatchGroup()
    private lazy var isPresentedModally: Bool = { return (navigationController?.isBeingPresented ?? false) || isBeingPresented }()
    private lazy var cancelBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tappedCancel))
    }()
    lazy private var paymentManager: PaymentAuthorizationManager = {
        let manager = PaymentAuthorizationManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    private var order: Order {
        return OrderManager.shared.basketOrder
    }
    
    private var redirectContext: STPRedirectContext?
    
    var dismissClosure: ((_ source: UIViewController, _ success: Bool) -> ())?
    
    private var dispatchGroup: DispatchGroup? = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        Analytics.shared.trackScreenViewed(.basket)
        
        title = Constants.title
        if PhotobookSDK.shared.environment == .test {
            title = title! + " (TEST)"
        }
        if PhotobookSDK.shared.shouldUseStaging {
            title = title! + " - STAGING"
        }
        
        guard PhotobookSDK.shared.kiteUrlScheme != nil else {
            return
        }

        registerForKeyboardNotifications()
        
        // Clear fields
        deliveryDetailsLabel.text = nil
        shippingMethodLabel.text = nil
        paymentMethodLabel.text = nil
        
        promoCodeTextField.placeholder = Constants.promoCodePlaceholderText
        
        payButtonOriginalColor = payButton.backgroundColor
        payButton.addTarget(self, action: #selector(CheckoutViewController.payButtonTapped(_:)), for: .touchUpInside)
        
        // Apple Pay
        if PaymentAuthorizationManager.isApplePayAvailable {
            setupApplePayButton()
        }
        
        if isPresentedModally {
            navigationItem.leftBarButtonItems = [ cancelBarButtonItem ]
        }
        
        emptyScreenViewController.show(message: Constants.loadingDetailsText, activity: true)
        
        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(paymentAuthorized(_:)), name: PaymentNotificationName.authorized, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToCreateCustomerKey), name: KiteApiNotificationName.failedToCreateCustomerKey, object: nil)
    }
    
    private func setUpOrder() {
        order.deliveryDetails = OLDeliveryDetails.selectedDetails()
        
        // Load previously selected payment method
        let (paymentMethod, _) = SelectedPaymentMethodHandler.load()
        order.paymentMethod = paymentMethod
        
        if (order.paymentMethod == .applePay && !PaymentAuthorizationManager.isApplePayAvailable) ||
            (order.paymentMethod == .payPal && !PaymentAuthorizationManager.isPayPalAvailable) ||
            (order.paymentMethod == .creditCard && paymentManager.selectedPaymentOption() == nil) {
            order.paymentMethod = nil
        }
    }
    
    private var hasSetUpStripe = false
    @objc private func failedToCreateCustomerKey() {
        if apiClientError == nil {
            apiClientError = .generic
        }
        dispatchGroup?.leave()
    }
        
    @objc func paymentAuthorized(_ notification: NSNotification) {
        // Ignore if the basket is not the last controller in the navigation
        guard navigationController?.topViewController == self else { return }
        
        guard let parameters = notification.userInfo as? [String: String],
              let paymentIntentId = parameters["payment_intent"],
              let clientSecret = parameters["payment_intent_client_secret"] else {
            progressOverlayViewController.hide()
            present(UIAlertController(errorMessage: ErrorMessage(.generic)), animated: true)
            return
        }

        paymentManager.isPaymentAuthorized(withClientSecret: clientSecret) { [weak welf = self] authorized in
            guard let stelf = welf else { return }
            
            stelf.progressOverlayViewController.hide()
            if !authorized {
                let errorMessage = ErrorMessage(text: NSLocalizedString("Checkout/AuthorisationFailed", value: "Authorisation Failed", comment: "Message informing the user that the authorisation of their card failed"))
                MessageBarViewController.show(message: errorMessage, parentViewController: stelf, offsetTop: stelf.navigationController!.navigationBar.frame.maxY, centred: true)
                return
            }

            stelf.order.paymentToken = paymentIntentId
            stelf.showReceipt(after3DAuthorisation: true)
        }
    }
    
    private func detailsDidRefresh() {
        guard !order.products.isEmpty else {
            dismissBasket()
            return
        }

        OrderManager.shared.saveBasketOrder()
        
        emptyScreenViewController.hide()
        progressOverlayViewController.hide()
        promoCodeActivityIndicator.stopAnimating()
        promoCodeTextField.isUserInteractionEnabled = true
        
        setUpOrder()
        updateViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let topInset: CGFloat
        if #available(iOS 11, *) {
            topInset = 0
        } else {
            topInset = navigationController?.navigationBar.frame.maxY ?? 0
        }
        
        tableView.contentInset = UIEdgeInsets(top: topInset, left: tableView.contentInset.left, bottom: tableView.contentInset.bottom, right: tableView.contentInset.right)
        
        let rowHeight: CGFloat = UIScreen.main.bounds.width > Constants.smallDeviceScreenWidth ? Constants.largeDeviceTableViewCellHeight : Constants.smallDeviceTableViewCellHeight
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = rowHeight
        
        payButton.titleLabel?.sizeToFit()
    }
    
    private func showEmptyScreen() {
        let message = NSLocalizedString("Basket/EmptyBasketTitle", value: "Your basket is empty", comment: "Title shown to the user when the basket is empty")
        let buttonTitle = NSLocalizedString("Basket/EmptyBasketCTA", value: "Continue Shopping", comment: "Title for the button shown when basket is empty")
        emptyScreenViewController.show(message: message, title: nil, image: nil, buttonTitle: buttonTitle, buttonAction: { [weak welf = self] in
            welf?.tappedCancel()
        })
    }
    
    private func setupApplePayButton() {
        let applePayButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        self.applePayButton = applePayButton
        payButtonContainerView.addSubview(applePayButton)
        payButtonContainerView.clipsToBounds = true
        payButtonContainerView.cornerRadius = 10
        
        let views: [String: Any] = ["applePayButton": applePayButton]
        
        let vConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[applePayButton]|",
            metrics: nil,
            views: views)
        
        let hConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[applePayButton]|",
            metrics: nil,
            views: views)
        
        view.addConstraints(hConstraints + vConstraints)
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard PhotobookSDK.shared.kiteUrlScheme != nil else {
            let title = NSLocalizedString("Controllers/CheckoutViewController/EmptyScreenURLSchemeTitle", value: "URL Scheme Not Set", comment: "Title of the error displayed when the developers of the host app did not set up 3D Secure payments")
            let message = NSLocalizedString("Controllers/CheckoutViewController/EmptyScreenURLSchemeText", value: "A URL scheme is necessary to implement 3D Secure 2 payments. For more information please check our Quick Integration guide.", comment: "Text of the error displayed when the developers of the host app did not set up 3D Secure payments")
            emptyScreenViewController.show(message: message, title: title)
            return
        }
        
        if order.products.isEmpty {
            showEmptyScreen()
            return
        }
        
        refresh(showProgress: emptyScreenViewController.view.superview == nil)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc func tappedCancel() {
        guard dismissClosure != nil else {
            autoDismiss(true)
            return
        }
        
        let controllerToDismiss = isPresentedModally() ? navigationController! : self
        dismissClosure?(controllerToDismiss, false)
    }
    
    private func dismissBasket() {
        if isPresentedModally {
            tappedCancel()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private var apiClientError: APIClientError?
    private func refresh(showProgress: Bool = true, forceCostUpdate: Bool = false, forceShippingMethodsUpdate: Bool = false) {
        if showProgress {
            progressOverlayViewController.show(message: Constants.loadingDetailsText)
        }
        
        // Enter dispatch group for PaymentContext and Refresh calls
        dispatchGroup = DispatchGroup()
        dispatchGroup?.enter()
        
        dispatchGroup?.notify(queue: DispatchQueue.main, execute: { [weak welf = self] in
            guard let stelf = welf else { return }
            
            stelf.dispatchGroup = nil
            if let error = stelf.apiClientError {
                let errorMessage = ErrorMessage(error)
                
                var parsingError = false
                if case .parsing(_) = error {
                    OrderManager.shared.reset()
                    parsingError = true
                }

                if parsingError || !stelf.order.hasCachedCost {
                    stelf.emptyScreenViewController.show(message: errorMessage.text, title: errorMessage.title, image: nil, buttonTitle: parsingError ? nil : CommonLocalizedStrings.retry, buttonAction: { [weak welf = self] in
                        welf?.refresh(showProgress: showProgress, forceCostUpdate: forceCostUpdate, forceShippingMethodsUpdate: forceShippingMethodsUpdate)
                    })
                } else {
                    MessageBarViewController.show(message: ErrorMessage(error), parentViewController: stelf, offsetTop: stelf.navigationController!.navigationBar.frame.maxY, centred: true) {
                        welf?.refresh(showProgress: showProgress, forceCostUpdate: forceCostUpdate, forceShippingMethodsUpdate: forceShippingMethodsUpdate)
                    }
                }
                
                stelf.apiClientError = nil
                return
            }
            
            stelf.detailsDidRefresh()
        })
        
        if !hasSetUpStripe {
            dispatchGroup?.enter()
            paymentManager.stripeHostViewController = self
        }
        
        if order.paymentMethod == .creditCard {
            order.deliveryDetails = OLDeliveryDetails.selectedDetails()
        }
        order.updateCost(forceUpdate: forceCostUpdate, forceShippingMethodUpdate: forceShippingMethodsUpdate) { [weak welf = self] (error) in
            guard let stelf = welf else { return }
            
            if let error = error {
                stelf.apiClientError = error
            }
            
            stelf.dispatchGroup?.leave()
        }
    }
    
    private func updateProductCell(_ cell: BasketProductTableViewCell, for index: Int) {
        let product = order.products[index]
        
        guard let lineItems = order.cost?.lineItems,
            index < lineItems.count,
            let lineItem = order.lineItem(for: product)
            else {
                return
        }
        
        cell.productDescriptionLabel.text = lineItem.name
        cell.priceLabel.text = lineItem.price.formatted
        cell.itemAmountButton.setTitle("\(product.itemCount)", for: .normal)
        cell.itemAmountButton.accessibilityValue = cell.itemAmountButton.title(for: .normal)
        cell.productIdentifier = product.identifier
        cell.productImageView.image = nil
        product.previewImage(size: cell.productImageView.frame.size * UIScreen.main.scale, completionHandler: { image in
            guard product.identifier == cell.productIdentifier else {
                return
            }
            
            cell.productImageView.image = image
        })
    }
    
    private func updateViews() {
        
        // Products
        for index in 0..<order.products.count {
            guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BasketProductTableViewCell else {
                continue
            }
            updateProductCell(cell, for: index)
        }
        
        // Promo code
        if let promoDiscount = order.cost?.promoDiscount, promoDiscount.value != 0 {
            promoCodeTextField.text = "-" + promoDiscount.formatted
            previousPromoText = promoDiscount.formatted
            promoCodeClearButton.isHidden = false
            promoCodeAccessoryConstraint.priority = .defaultHigh
            promoCodeNormalConstraint.priority = .defaultLow
        }
        
        let promoCodeIsInvalid = checkPromoCode()
        
        // Payment Method Icon
        showDeliveryDetailsConstraint.priority = .defaultHigh
        hideDeliveryDetailsConstraint.priority = .defaultLow
        deliveryDetailsView.isHidden = false
        paymentMethodIconImageView.image = nil
        if let paymentMethod = order.paymentMethod {
            switch paymentMethod {
            case .creditCard where paymentManager.selectedPaymentOption() != nil:
                let card = paymentManager.selectedPaymentOption()!
                paymentMethodIconImageView.image = card.image
                paymentMethodView.accessibilityValue = card.label
                paymentMethodTitleLabel.text = Constants.payingWithText
            case .applePay:
                paymentMethodIconImageView.image = UIImage(namedInPhotobookBundle: "apple-pay-method")
                paymentMethodView.accessibilityValue = "Apple Pay"
                showDeliveryDetailsConstraint.priority = .defaultLow
                hideDeliveryDetailsConstraint.priority = .defaultHigh
                deliveryDetailsView.isHidden = true
                paymentMethodTitleLabel.text = Constants.payingWithText
            case .payPal:
                paymentMethodIconImageView.image = UIImage(namedInPhotobookBundle: "paypal-method")
                paymentMethodView.accessibilityValue = "PayPal"
                paymentMethodTitleLabel.text = Constants.payingWithText
            default:
                order.paymentMethod = nil
            }
            paymentMethodIconImageView.isHidden = false
            paymentMethodLabel.isHidden = true
        }
        
        // Shipping
        shippingMethodLabel.text = ""
        if let cost = order.cost {
            shippingMethodLabel.text = cost.totalShippingPrice.formatted
        }
        
        // Address
        var addressString = ""
        if let details = order.deliveryDetails, let line1 = details.line1 {
            
            addressString = line1
            if let line2 = details.line2, !line2.isEmpty { addressString = addressString + ", " + line2 }
            if let postcode = details.zipOrPostcode, !postcode.isEmpty { addressString = addressString + ", " + postcode }
            if !details.country.name.isEmpty { addressString = addressString + ", " + details.country.name }
            
            //reset view
            deliveryDetailsLabel.textColor = Constants.detailsLabelColor
            deliveryDetailsLabel.text = addressString
        }
        
        // CTA button
        adaptPayButton()
        
        // Accessibility
        deliveryDetailsView.accessibilityLabel = infoLabelDeliveryDetails.text
        deliveryDetailsView.accessibilityValue = deliveryDetailsLabel.text
        
        shippingMethodView.accessibilityLabel = infoLabelShipping.text
        shippingMethodView.accessibilityValue = shippingMethodLabel.text
        
        paymentMethodView.accessibilityLabel = paymentMethodTitleLabel.text
        
        if promoCodeIsInvalid {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: promoCodeTextField)
        }
    }
    
    private func adaptPayButton() {
        // Hide all
        applePayButton?.isHidden = true
        applePayButton?.isEnabled = false
        payButton.isHidden = true
        payButton.isEnabled = false
        
        var payButtonText = NSLocalizedString("Controllers/CheckoutViewController/PayButtonText",
                                              value: "Pay",
                                              comment: "Text on pay button. This is followed by the amount to pay")
        
        if let cost = order.cost {
            payButtonText = payButtonText + " \(cost.total.formatted)"
        }
        payButton.setTitle(payButtonText, for: .normal)
        
        let paymentMethod = order.paymentMethod
        
        if paymentMethod == .applePay {
            applePayButton?.isHidden = false
            applePayButton?.isEnabled = true
        } else {
            payButton.isHidden = false
            payButton.isEnabled = true
            payButton.alpha = 1.0
            payButton.backgroundColor = payButtonOriginalColor
            
            var payButtonAccessibilityLabel = payButtonText
            var payButtonHint: String?
            
            let paymentMethodIsValid = self.paymentMethodIsValid()
            let deliveryDetailsAreValid = self.deliveryDetailsAreValid()
            if !paymentMethodIsValid || !deliveryDetailsAreValid {
                payButton.alpha = 0.5
                payButton.backgroundColor = UIColor.lightGray
                payButtonAccessibilityLabel += ". Disabled."
                
                if !paymentMethodIsValid && !deliveryDetailsAreValid {
                    payButtonHint = NSLocalizedString("Accessibility/AddPaymentMethodAndDeliveryDetailsHint", value: "Add a payment method and delivery details to place your order.", comment: "Accessibility hint letting the user know that they need to add a payment method and delivery details to be able to place the order.")
                } else if !paymentMethodIsValid {
                    payButtonHint = NSLocalizedString("Accessibility/AddPaymentMethodHint", value: "Add a payment method to place your order.", comment: "Accessibility hint letting the user know that they need to add a payment method to be able to place the order.")
                } else if !deliveryDetailsAreValid {
                    payButtonHint = NSLocalizedString("Accessibility/AddDeliveryDetailsHint", value: "Enter delivery details to place your order.", comment: "Accessibility hint letting the user know that they need to enter delivery details to be able to place the order.")
                }
            }
            payButton.accessibilityLabel = payButtonAccessibilityLabel
            payButton.accessibilityHint = payButtonHint
        }
    }
    
    private func indicatePaymentMethodError() {
        paymentMethodIconImageView.isHidden = true
        paymentMethodLabel.isHidden = false
        paymentMethodLabel.text = Constants.labelRequiredText
        paymentMethodLabel.textColor = Constants.detailsLabelColorRequired
        paymentMethodTitleLabel.text = Constants.paymentMethodText
        
        paymentMethodView.accessibilityValue = Constants.labelRequiredText
    }
    
    private func deliveryDetailsAreValid() -> Bool {
        return (!order.orderIsFree && order.paymentMethod == .applePay) || (order.deliveryDetails?.isValid ?? false)
    }
    
    private func paymentMethodIsValid() -> Bool {
        return order.orderIsFree || (order.paymentMethod != nil && (order.paymentMethod != .creditCard || paymentManager.selectedPaymentOption() != nil))
    }
    
    private func indicateDeliveryDetailsError() {
        deliveryDetailsLabel.text = Constants.labelRequiredText
        deliveryDetailsLabel.textColor = Constants.detailsLabelColorRequired
        
        deliveryDetailsView.accessibilityValue = Constants.labelRequiredText
    }
    
    private func checkRequiredInformation() -> Bool {
        let paymentMethodIsValid = self.paymentMethodIsValid()
        if !paymentMethodIsValid {
            indicatePaymentMethodError()
        }
        
        let deliveryDetailsAreValid = self.deliveryDetailsAreValid()
        if !deliveryDetailsAreValid {
            indicateDeliveryDetailsError()
        }
        
        return deliveryDetailsAreValid && paymentMethodIsValid
    }
    
    private func checkPromoCode() -> Bool {
        //promo code
        if let invalidReason = order.cost?.promoCodeInvalidReason {
            promoCodeTextField.attributedPlaceholder = NSAttributedString(string: invalidReason, attributes: [NSAttributedString.Key.foregroundColor: Constants.detailsLabelColorRequired])
            promoCodeTextField.text = nil
            promoCodeTextField.placeholder = invalidReason
            
            self.promoCodeClearButton.isHidden = true
            self.promoCodeAccessoryConstraint.priority = .defaultLow
            self.promoCodeNormalConstraint.priority = .defaultHigh
            
            return true
        }
        
        return false
    }
    
    private func handlePromoCodeChanges() {
        
        guard let text = promoCodeTextField.text else {
            return
        }
        
        //textfield is empty
        if text.isEmpty {
            if !promoCodeTextField.isFirstResponder {
                promoCodeClearButton.isHidden = true
                promoCodeAccessoryConstraint.priority = .defaultLow
                promoCodeNormalConstraint.priority = .defaultHigh
            }
            if order.promoCode != nil { //it wasn't empty before
                order.promoCode = nil
                refresh(showProgress: false)
            }
            return
        }
        
        // is not empty
        if previousPromoText != text { //and it has changed
            order.promoCode = text
            promoCodeAccessoryConstraint.priority = .defaultHigh
            promoCodeNormalConstraint.priority = .defaultLow
            promoCodeActivityIndicator.startAnimating()
            promoCodeTextField.isUserInteractionEnabled = false
            promoCodeClearButton.isHidden = true
            refresh(showProgress: false)
        }
    }
    
    private func showReceipt(after3DAuthorisation: Bool = false) {
        order.lastSubmissionDate = Date()
        NotificationCenter.default.post(name: OrdersNotificationName.orderWasCreated, object: order)
        
        OrderManager.shared.saveBasketOrder()
        
        if presentedViewController == nil {
            performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
        } else if after3DAuthorisation {
            // The 3D secure dialog (SFSafariViewController) dismisses itself
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
            })
        } else {
            dismiss(animated: true) {
                self.performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Constants.receiptSegueName:
            if let receiptViewController = segue.destination as? ReceiptViewController {
                receiptViewController.order = order
                receiptViewController.dismissClosure = dismissClosure
            }
        case Constants.segueIdentifierPaymentMethods:
            if let paymentMethodsViewController = segue.destination as? PaymentMethodsViewController {
                paymentMethodsViewController.order = order
                paymentMethodsViewController.paymentManager = paymentManager
            }
        case Constants.segueIdentifierAddressInput:
            if let addressTableViewController = segue.destination as? AddressTableViewController {
                addressTableViewController.delegate = self
            }
        default:
            break
        }
    }
    
    //MARK: - Actions
    
    @IBAction func promoCodeDismissViewTapped(_ sender: Any) {
        promoCodeTextField.resignFirstResponder()
        promoCodeDismissGestureRecognizer.isEnabled = false
        
        handlePromoCodeChanges()
        promoCodeTextField.setNeedsLayout()
        promoCodeTextField.layoutIfNeeded()
    }
    
    @IBAction func promoCodeViewTapped(_ sender: Any) {
        promoCodeTextField.becomeFirstResponder()
    }
    
    @IBAction func promoCodeClearButtonTapped(_ sender: Any) {
        promoCodeTextField.text = ""
        handlePromoCodeChanges()
    }
    
    @IBAction private func presentAmountPicker(selectedAmount: Int) {
        let amountPickerViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "AmountPickerViewController") as! AmountPickerViewController
        amountPickerViewController.optionName = NSLocalizedString("Controllers/CheckoutViewController/ItemAmountPickerTitle",
                                                                              value: "Select amount",
                                                                              comment: "The title displayed on the picker view for the amount of basket items")
        amountPickerViewController.selectedValue = selectedAmount
        amountPickerViewController.minimum = 1
        amountPickerViewController.maximum = 10
        amountPickerViewController.delegate = self
        amountPickerViewController.modalPresentationStyle = .overCurrentContext
        self.present(amountPickerViewController, animated: false, completion: nil)
    }
    
    @IBAction func deliveryDetailsTapped(_ sender: UITapGestureRecognizer) {
        if OLDeliveryDetails.savedDeliveryDetails.count == 0 {
            performSegue(withIdentifier: Constants.segueIdentifierAddressInput, sender: nil)
            return
        }
        performSegue(withIdentifier: Constants.segueIdentifierDeliveryDetails, sender: nil)
    }
    
    @IBAction func payButtonTapped(_ sender: UIButton) {
        guard checkRequiredInformation() else { return }
        
        guard let cost = order.cost else {
            progressOverlayViewController.show(message: Constants.loadingPaymentText)
            order.updateCost { [weak welf = self] (error: Error?) in
                guard error == nil else {
                    guard let stelf = welf else { return }
                    MessageBarViewController.show(message: ErrorMessage(error!), parentViewController: stelf, offsetTop: stelf.navigationController!.navigationBar.frame.maxY, centred: true) {
                        welf?.payButtonTapped(sender)
                    }
                    return
                }
                
                welf?.progressOverlayViewController.hide()
                welf?.payButtonTapped(sender)
            }
            return
        }
            
        if cost.total.value == 0.0 {
            // The user must have a promo code which reduces this order cost to nothing, lucky user :)
            order.paymentToken = nil
            showReceipt()
        }
        else {
            if order.paymentMethod == .applePay {
                modalPresentationDismissedGroup.enter()
            }
            
            guard let paymentMethod = order.paymentMethod else { return }
            
            progressOverlayViewController.show(message: Constants.loadingPaymentText)
            paymentManager.stripeHostViewController = self
            paymentManager.authorizePayment(cost: cost, method: paymentMethod)
        }
    }
    
    //MARK: Keyboard Notifications
    
    @objc func keyboardWillChangeFrame(notification: Notification) {
        let userInfo = notification.userInfo
        guard let size = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        let time = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.5
        
        guard promoCodeTextField.isFirstResponder else { return }
        
        optionsViewTopConstraint.constant =  -size.height - promoCodeViewHeightConstraint.constant
        
        self.optionsViewBottomContraint.priority = .defaultLow
        self.optionsViewTopConstraint.priority = .defaultHigh
        UIView.animate(withDuration: time) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: Notification){
        guard promoCodeTextField.isFirstResponder else { return }
        let userInfo = notification.userInfo
        let time = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.5
        
        self.optionsViewBottomContraint.priority = .defaultHigh
        self.optionsViewTopConstraint.priority = .defaultLow
        UIView.animate(withDuration: time) {
            self.view.layoutIfNeeded()
        }
    }
}

extension CheckoutViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        promoCodeDismissGestureRecognizer.isEnabled = true
        
        previousPromoText = textField.text
        promoCodeTextField.placeholder = Constants.promoCodePlaceholderText
        //display delete button
        promoCodeClearButton.isHidden = false
        promoCodeAccessoryConstraint.priority = .defaultHigh
        promoCodeNormalConstraint.priority = .defaultLow
        
        textField.setNeedsLayout()
        textField.layoutIfNeeded()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        promoCodeDismissGestureRecognizer.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        handlePromoCodeChanges()
        textField.setNeedsLayout()
        textField.layoutIfNeeded()
        
        return false
    }
}

extension CheckoutViewController: AmountPickerDelegate {
    func amountPickerDidSelectValue(_ value: Int) {
        guard let index = editingProductIndex else { return }
        
        order.products[index].itemCount = value
        refresh()
    }
}

extension CheckoutViewController: PaymentAuthorizationManagerDelegate {
    
    func paymentAuthorizationRequiresAction(withContext context: STPRedirectContext) {
        redirectContext = context
        redirectContext?.startRedirectFlow(from: self)
        progressOverlayViewController.hide()
    }
    
    func paymentAuthorizationManagerDidUpdateDetails() {
        if !hasSetUpStripe {
            hasSetUpStripe = true
            dispatchGroup?.leave()
            return
        }
        updateViews()
    }
    
    func costUpdated() {
        updateViews()
    }
    
    func modalPresentationWillBegin() {
        progressOverlayViewController.hide()
    }
    
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {
        if let error = error {
            progressOverlayViewController.hide()
            self.present(UIAlertController(errorMessage: ErrorMessage(error)), animated: true)
            return
        }
        
        order.paymentToken = token
        showReceipt()
    }
    
    func modalPresentationDidFinish() {
        order.updateCost { [weak welf = self] (error: Error?) in
            guard let stelf = welf else { return }
            
            stelf.modalPresentationDismissedGroup.leave()
            
            OrderManager.shared.saveBasketOrder()
            
            if let error = error {
                MessageBarViewController.show(message: ErrorMessage(error), parentViewController: stelf, offsetTop: stelf.navigationController!.navigationBar.frame.maxY, centred: true) {
                    welf?.modalPresentationDidFinish()
                }
                return
            }
        }
    }
    
}

extension CheckoutViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return order.products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BasketProductTableViewCell.reuseIdentifier, for: indexPath) as! BasketProductTableViewCell
        updateProductCell(cell, for: indexPath.row)
        cell.delegate = self
        return cell
    }
}

extension CheckoutViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            order.products.remove(at: indexPath.row)
            OrderManager.shared.saveBasketOrder()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            guard !order.products.isEmpty else {
                dismissBasket()
                return
            }
            refresh(forceCostUpdate: true, forceShippingMethodsUpdate: false)
        }
    }
}

extension CheckoutViewController: BasketProductTableViewCellDelegate {
    func didTapAmountButton(for productIdentifier: String) {
        editingProductIndex = order.products.firstIndex(where: { $0.identifier == productIdentifier })
        let selectedAmount = editingProductIndex != nil ? order.products[editingProductIndex!].itemCount : 1
        presentAmountPicker(selectedAmount: selectedAmount)
    }
}

extension CheckoutViewController: AddressTableViewControllerDelegate {
    
    func addressTableViewControllerDidEdit() {
        navigationController?.popViewController(animated: true)
    }
}
