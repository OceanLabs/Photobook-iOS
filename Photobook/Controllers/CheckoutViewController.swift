//
//  CheckoutViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
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
        
        static let detailsLabelColor = UIColor.black
        static let detailsLabelColorRequired = UIColor.red.withAlphaComponent(0.6)
        
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
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemAmountButton: UIButton!
    
    @IBOutlet weak var promoCodeActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var promoCodeTextField: UITextField!
    @IBOutlet weak var promoCodeClearButton: UIButton!
    @IBOutlet weak var deliveryDetailsView: UIView!
    @IBOutlet weak var deliveryDetailsLabel: UILabel!
    @IBOutlet weak var shippingMethodView: UIView!
    @IBOutlet weak var shippingMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodView: UIView!
    @IBOutlet weak var paymentMethodTitleLabel: UILabel!
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodIconImageView: UIImageView!
    @IBOutlet weak var payButtonContainerView: UIView!
    @IBOutlet weak var payButton: UIButton!
    private var applePayButton: PKPaymentButton?
    private var payButtonOriginalColor:UIColor!

    @IBOutlet var promoCodeDismissGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var hideDeliveryDetailsConstraint: NSLayoutConstraint!
    @IBOutlet weak var showDeliveryDetailsConstraint: NSLayoutConstraint!
    @IBOutlet weak var optionsViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var optionsViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var promoCodeViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var promoCodeAccessoryConstraint: NSLayoutConstraint!
    @IBOutlet weak var promoCodeNormalConstraint: NSLayoutConstraint!
    
    private var previousPromoText: String? //stores previously entered promo string to determine if it has changed
    
    private var modalPresentationDismissedGroup = DispatchGroup()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(Analytics.ScreenName.basket)
        
        if PhotobookManager.environment == .test {
            title = Constants.title + " (TEST)"
        } else {
            title = Constants.title
        }
        
        registerForKeyboardNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryPreviewImageReady), name: OrderSummaryManager.notificationPreviewImageReady, object: nil)
        
        //clear fields
        deliveryDetailsLabel.text = nil
        shippingMethodLabel.text = nil
        paymentMethodLabel.text = nil
        
        promoCodeTextField.placeholder = Constants.promoCodePlaceholderText
        
        payButtonOriginalColor = payButton.backgroundColor
        payButton.addTarget(self, action: #selector(CheckoutViewController.payButtonTapped(_:)), for: .touchUpInside)
        
        //APPLE PAY
        if Stripe.deviceSupportsApplePay() {
            setupApplePayButton()
        }
        
        //POPULATE
        refresh()
        emptyScreenViewController.show(message: Constants.loadingDetailsText, activity: true)
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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !OrderManager.basketOrder.hasValidCachedCost {
            refresh(false)
        } else {
            updateViews()
        }
    }
    
    private func refresh(_ showProgress: Bool = true) {
        if showProgress {
            progressOverlayViewController.show(message: Constants.loadingDetailsText)
        }
        
        OrderManager.basketOrder.updateCost { (error) in
            
            if let error = error {
                let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default)
                alert.addAction(okAction)
                self.present(alert, animated: true)
                return
            }
            
            self.emptyScreenViewController.hide()
            self.progressOverlayViewController.hide()
            self.promoCodeActivityIndicator.stopAnimating()
            self.promoCodeTextField.isUserInteractionEnabled = true
            
            self.updateViews()
        }
    }
    
    private func updateItemImage() {
        let scaleFactor = UIScreen.main.scale
        let size = CGSize(width: itemImageView.frame.size.width * scaleFactor, height: itemImageView.frame.size.height * scaleFactor)
        
        OrderSummaryManager.shared.fetchPreviewImage(withSize: size) { (image) in
            self.itemImageView.image = image
        }
    }
    
    private func updateViews() {
        
        //product
        itemTitleLabel.text = ProductManager.shared.product?.name
        itemPriceLabel.text = OrderManager.basketOrder.cachedCost?.lineItems?.first?.formattedCost
        itemAmountButton.setTitle("\(OrderManager.basketOrder.itemCount)", for: .normal)
        updateItemImage()
        
        //promo code
        if let promoDiscount = OrderManager.basketOrder.validCost?.promoDiscount {
            promoCodeTextField.text = promoDiscount
            previousPromoText = promoDiscount
            promoCodeClearButton.isHidden = false
            promoCodeAccessoryConstraint.priority = .defaultHigh
            promoCodeNormalConstraint.priority = .defaultLow
        }
        checkPromoCode()
        
        //payment method icon
        showDeliveryDetailsConstraint.priority = .defaultHigh
        hideDeliveryDetailsConstraint.priority = .defaultLow
        deliveryDetailsView.isHidden = false
        paymentMethodIconImageView.image = nil
        if let paymentMethod = OrderManager.basketOrder.paymentMethod {
            switch paymentMethod {
            case .creditCard:
                if let card = Card.currentCard {
                    paymentMethodIconImageView.image = card.cardIcon
                } else {
                    paymentMethodIconImageView.image = nil
                }
            case .applePay:
                paymentMethodIconImageView.image = UIImage(namedInPhotobookBundle: "apple-pay-method")
                showDeliveryDetailsConstraint.priority = .defaultLow
                hideDeliveryDetailsConstraint.priority = .defaultHigh
                deliveryDetailsView.isHidden = true
            case .payPal:
                paymentMethodIconImageView.image = UIImage(namedInPhotobookBundle: "paypal-method")
            }
            paymentMethodIconImageView.isHidden = false
            paymentMethodLabel.isHidden = true
            paymentMethodTitleLabel.text = Constants.payingWithText
        }
        
        //shipping
        shippingMethodLabel.text = ""
        if let validCost = OrderManager.basketOrder.validCost, let selectedShippingMethod = validCost.shippingMethod(id: OrderManager.basketOrder.shippingMethod) {
            shippingMethodLabel.text = selectedShippingMethod.shippingCostFormatted
        }
        
        //address
        var addressString = ""
        if let address = OrderManager.basketOrder.deliveryDetails?.address, let line1 = address.line1 {
            
            addressString = line1
            if let line2 = address.line2, !line2.isEmpty { addressString = addressString + ", " + line2 }
            if let postcode = address.zipOrPostcode, !postcode.isEmpty { addressString = addressString + ", " + postcode }
            if !address.country.name.isEmpty { addressString = addressString + ", " + address.country.name }
            
            //reset view
            deliveryDetailsLabel.textColor = Constants.detailsLabelColor
            deliveryDetailsLabel.text = addressString
        }
        
        //CTA button
        adaptPayButton()
    }
    
    private func adaptPayButton() {
        //hide all
        applePayButton?.isHidden = true
        applePayButton?.isEnabled = false
        payButton.isHidden = true
        payButton.isEnabled = false
        
        var payButtonText = NSLocalizedString("Controllers/CheckoutViewController/PayButtonText",
                                              value: "Pay",
                                              comment: "Text on pay button. This is followed by the amount to pay")
        
        if let selectedMethod = OrderManager.basketOrder.shippingMethod, let cost = OrderManager.basketOrder.validCost, let shippingMethod = cost.shippingMethod(id: selectedMethod) {
            payButtonText = payButtonText + " \(shippingMethod.totalCostFormatted)"
        }
        payButton.setTitle(payButtonText, for: .normal)
        
        let paymentMethod = OrderManager.basketOrder.paymentMethod
        
        if paymentMethod == .applePay {
            applePayButton?.isHidden = false
            applePayButton?.isEnabled = true
        } else {
            payButton.isHidden = false
            payButton.isEnabled = true
            payButton.alpha = 1.0
            payButton.backgroundColor = payButtonOriginalColor
            if paymentMethod == nil {
                payButton.alpha = 0.5
                payButton.backgroundColor = UIColor.lightGray
            }
        }
    }
    
    private func paymentMethodIsValid() -> Bool {
        guard OrderManager.basketOrder.orderIsFree || (OrderManager.basketOrder.paymentMethod != nil && (OrderManager.basketOrder.paymentMethod != .creditCard || Card.currentCard != nil)) else {
            indicatePaymentMethodError()
            return false
        }
        
        return true
    }
    
    private func indicatePaymentMethodError() {
        paymentMethodIconImageView.isHidden = true
        paymentMethodLabel.isHidden = false
        paymentMethodLabel.text = Constants.labelRequiredText
        paymentMethodLabel.textColor = Constants.detailsLabelColorRequired
        paymentMethodTitleLabel.text = Constants.paymentMethodText
    }
    
    private func deliveryDetailsAreValid() -> Bool {
        guard (!OrderManager.basketOrder.orderIsFree && OrderManager.basketOrder.paymentMethod == .applePay) || (OrderManager.basketOrder.deliveryDetails?.address?.isValid ?? false) else {
            indicateDeliveryDetailsError()
            return false
        }
        
        return true
    }
    
    private func indicateDeliveryDetailsError() {
        deliveryDetailsLabel.text = Constants.labelRequiredText
        deliveryDetailsLabel.textColor = Constants.detailsLabelColorRequired
    }
    
    private func detailFieldsAreValid() -> Bool {
        let paymentMethodIsValid = self.paymentMethodIsValid()
        return deliveryDetailsAreValid() && paymentMethodIsValid
    }
    
    private func checkPromoCode() {
        //promo code
        if let invalidReason = OrderManager.basketOrder.validCost?.promoCodeInvalidReason {
            promoCodeTextField.attributedPlaceholder = NSAttributedString(string: invalidReason, attributes: [NSAttributedStringKey.foregroundColor: Constants.detailsLabelColorRequired])
            promoCodeTextField.text = nil
            promoCodeTextField.placeholder = invalidReason
            
            self.promoCodeClearButton.isHidden = true
            self.promoCodeAccessoryConstraint.priority = .defaultLow
            self.promoCodeNormalConstraint.priority = .defaultHigh
        }
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
            if OrderManager.basketOrder.promoCode != nil { //it wasn't empty before
                OrderManager.basketOrder.promoCode = nil
                refresh(false)
            }
            return
        }
        
        //textfield is not empty
        if previousPromoText != text { //and it has changed
            OrderManager.basketOrder.promoCode = text
            promoCodeAccessoryConstraint.priority = .defaultHigh
            promoCodeNormalConstraint.priority = .defaultLow
            promoCodeActivityIndicator.startAnimating()
            promoCodeTextField.isUserInteractionEnabled = false
            promoCodeClearButton.isHidden = true
            refresh(false)
        }
    }
    
    private func showReceipt() {
        OrderManager.basketOrder.lastSubmissionDate = Date()
        NotificationCenter.default.post(name: OrdersNotificationName.orderWasCreated, object: OrderManager.basketOrder)
        
        OrderManager.shared.saveBasketOrder()
        
        if self.presentedViewController == nil {
            self.performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
        }
        else {
            self.dismiss(animated: true, completion: {
                self.performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.receiptSegueName {
            (segue.destination as? ReceiptTableViewController)?.order = OrderManager.basketOrder
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
    
    @IBAction public func itemAmountButtonTapped(_ sender: Any) {
        presentAmountPicker()
    }
    
    @IBAction func promoCodeClearButtonTapped(_ sender: Any) {
        promoCodeTextField.text = ""
        handlePromoCodeChanges()
    }
    
    @IBAction private func presentAmountPicker() {
        let amountPickerViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "AmountPickerViewController") as! AmountPickerViewController
        amountPickerViewController.optionName = NSLocalizedString("Controllers/CheckoutViewController/ItemAmountPickerTitle",
                                                                              value: "Select amount",
                                                                              comment: "The title displayed on the picker view for the amount of basket items")
        amountPickerViewController.selectedValue = OrderManager.basketOrder.itemCount
        amountPickerViewController.minimum = 1
        amountPickerViewController.maximum = 10
        amountPickerViewController.delegate = self
        amountPickerViewController.modalPresentationStyle = .overCurrentContext
        self.present(amountPickerViewController, animated: false, completion: nil)
    }
    
    @IBAction func payButtonTapped(_ sender: UIButton) {
        guard detailFieldsAreValid() else { return }
        
        guard let cost = OrderManager.basketOrder.validCost else {
            progressOverlayViewController.show(message: Constants.loadingPaymentText)
            OrderManager.basketOrder.updateCost { [weak welf = self] (error: Error?) in
                guard error == nil else {
                    let genericError = NSLocalizedString("UpdateCostError", value: "An error occurred while updating our products.\nPlease try again later.", comment: "Generic error when retrieving the cost for the products in the basket")
                    
                    let alert = UIAlertController(title: nil, message: genericError, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default)
                    alert.addAction(okAction)
                    self.present(alert, animated: true)
                    return
                }
                
                welf?.progressOverlayViewController.hide()
                welf?.payButtonTapped(sender)
            }
            return
        }
            
        if let selectedMethod = OrderManager.basketOrder.shippingMethod, let shippingMethod = cost.shippingMethod(id: selectedMethod), shippingMethod.totalCost == 0.0 {
            // The user must have a promo code which reduces this order cost to nothing, lucky user :)
            OrderManager.basketOrder.paymentToken = nil
            showReceipt()
        }
        else{
            if OrderManager.basketOrder.paymentMethod == .applePay{
                modalPresentationDismissedGroup.enter()
            }
            
            guard let paymentMethod = OrderManager.basketOrder.paymentMethod else { return }
            
            progressOverlayViewController.show(message: Constants.loadingPaymentText)
            paymentManager.authorizePayment(cost: cost, method: paymentMethod)
        }
    }
    
    //MARK: Order Summary Notifications
    
    @objc func orderSummaryPreviewImageReady() {
        updateItemImage()
    }
    
    //MARK: Keyboard Notifications
    
    @objc func keyboardWillChangeFrame(notification: Notification) {
        let userInfo = notification.userInfo
        guard let size = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        let time = (userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.5
        
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
        let time = (userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.5
        
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
        OrderManager.basketOrder.itemCount = value
        itemAmountButton.setTitle("\(value)", for: .normal)
    }
}

extension CheckoutViewController: PaymentAuthorizationManagerDelegate {
    
    func costUpdated() {
        updateViews()
    }
    
    func modalPresentationWillBegin() {
        progressOverlayViewController.hide()
    }
    
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {
        if let errorMessage = ErrorMessage(error) {
            progressOverlayViewController.hide()
            self.present(UIAlertController(errorMessage: errorMessage), animated: true)
            return
        }
        
        OrderManager.basketOrder.paymentToken = token
        
        showReceipt()
    }
    
    func modalPresentationDidFinish() {
        OrderManager.basketOrder.updateCost { [weak welf = self] (error: Error?) in
            guard welf != nil else { return }
            
            welf?.modalPresentationDismissedGroup.leave()
            
            if let errorMessage = ErrorMessage(error) {
                self.present(UIAlertController(errorMessage: errorMessage), animated: true)
                return
            }
        }
    }
    
}
