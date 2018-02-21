//
//  CheckoutViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import PassKit

class CheckoutViewController: UIViewController {
    
    private struct Constants {
        static let receiptSegueName = "ReceiptSegue"
        
        static let segueIdentifierDeliveryDetails = "segueDeliveryDetails"
        static let segueIdentifierShippingMethods = "segueShippingMethods"
        static let segueIdentifierPaymentMethods = "seguePaymentMethods"
        
        static let detailsLabelColor = UIColor.black
        static let detailsLabelColorRequired = UIColor.red
        
        static let titleText = NSLocalizedString("Controllers/CheckoutViewController/titleText",
                                                                 value: "Payment",
                                                                 comment: "Title of the checkout/basket screen")
        static let loadingDetailsText = NSLocalizedString("Controllers/CheckoutViewController/EmptyScreenLoadingText",
                                                    value: "Loading price details...",
                                                    comment: "Info text displayed next to a loading indicator while loading price details")
        static let loadingPaymentText = NSLocalizedString("Controllers/CheckoutViewController/PaymentLoadingText",
                                                   value: "Preparing payment...",
                                                   comment: "Info text displayed while preparing for payment service")
        static let labelRequiredText = NSLocalizedString("Controllers/CheckoutViewController/LabelRequiredText",
                                                          value: "Required",
                                                          comment: "Hint on empty but required order text fields if user clicks on pay")
        static let payingWithText = NSLocalizedString("Controllers/CheckoutViewController/PaymentMethodText",
                                                         value: "Paying with",
                                                         comment: "Left side of payment method row if a payment method is selected")
        static let paymentMethodText = NSLocalizedString("Controllers/CheckoutViewController/PaymentMethodRequiredText",
                                                                 value: "Payment Method",
                                                                 comment: "Left side of payment method row if required hint is displayed")
    }
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemAmountButton: UIButton!
    
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var promoCodeTextField: UITextField!
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
    
    @IBOutlet weak var hideDeliveryDetailsConstraint: NSLayoutConstraint!
    @IBOutlet weak var showDeliveryDetailsConstraint: NSLayoutConstraint!
    @IBOutlet weak var optionsViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var optionsViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var promoCodeViewHeightConstraint: NSLayoutConstraint!
    
    private var modalPresentationDismissedOperation : Operation?
    lazy private var paymentManager: PaymentAuthorizationManager = {
        let manager = PaymentAuthorizationManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var transitionOperation : BlockOperation = BlockOperation(block: { [unowned self] in
        if self.presentedViewController == nil{
            self.performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
            OrderManager.shared.reset()
        }
        else {
            self.dismiss(animated: true, completion: {
                self.performSegue(withIdentifier: Constants.receiptSegueName, sender: nil)
                OrderManager.shared.reset()
            })
        }
    })
    
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Constants.titleText
        
        registerForKeyboardNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryPreviewImageReady), name: OrderSummaryManager.notificationPreviewImageReady, object: nil)
        
        payButtonOriginalColor = payButton.backgroundColor
        payButton.addTarget(self, action: #selector(CheckoutViewController.payButtonTapped(_:)), for: .touchUpInside)
        
        //clear fields
        deliveryDetailsLabel.text = nil
        shippingMethodLabel.text = nil
        paymentMethodLabel.text = nil
        
        //APPLE PAY
        let applePayButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.addTarget(self, action: #selector(CheckoutViewController.applePayButtonTapped(_:)), for: .touchUpInside)
        self.applePayButton = applePayButton
        payButtonContainerView.addSubview(applePayButton)
        
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
        
        //POPULATE
        refresh()
        emptyScreenViewController.show(message: Constants.loadingDetailsText, title: nil, image: nil, activity: true, buttonTitle: nil, buttonAction: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViews()
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func refresh() {
        
        progressOverlayViewController.show(message: Constants.loadingDetailsText)
        OrderManager.shared.updateCost { (error) in
            self.updateViews() //TODO: error handling
            self.emptyScreenViewController.hide()
            self.progressOverlayViewController.hide()
        }
    }
    
    private func updateItemImage() {
        let scaleFactor = UIScreen.main.scale
        let size = CGSize(width: itemImageView.frame.size.width * scaleFactor, height: itemImageView.frame.size.height * scaleFactor)
        
        OrderSummaryManager.shared.fetchPreviewImage(withSize: size) { (image) in
            self.itemImageView.image = image
        }
    }
    
    private func checkDetailFields() {
        let requiredText = Constants.labelRequiredText
        
        //payment method
        if OrderManager.shared.paymentMethod == nil {
            paymentMethodIconImageView.isHidden = true
            paymentMethodLabel.isHidden = false
            paymentMethodLabel.text = requiredText
            paymentMethodLabel.textColor = Constants.detailsLabelColorRequired
            paymentMethodTitleLabel.text = Constants.paymentMethodText
        }
        
        //delivery details
        if OrderManager.shared.deliveryDetails == nil {
            deliveryDetailsLabel.text = requiredText
            deliveryDetailsLabel.textColor = Constants.detailsLabelColorRequired
        }
    }
    
    private func updateViews() {
        
        //product
        
        itemTitleLabel.text = ProductManager.shared.product?.name
        itemPriceLabel.text = OrderManager.shared.cachedCost?.lineItems?.first?.formattedCost
        itemAmountButton.setTitle("\(OrderManager.shared.itemCount)", for: .normal)
        updateItemImage()
        
        //payment method icon
        showDeliveryDetailsConstraint.priority = .defaultHigh
        hideDeliveryDetailsConstraint.priority = .defaultLow
        deliveryDetailsView.isHidden = false
        paymentMethodIconImageView.image = nil
        if let paymentMethod = OrderManager.shared.paymentMethod {
            switch paymentMethod {
            case .creditCard:
                if let card = Card.currentCard {
                    paymentMethodIconImageView.image = card.cardIcon
                } else {
                    paymentMethodIconImageView.image = nil
                }
            case .applePay:
                paymentMethodIconImageView.image = UIImage(named: "apple-pay-method")
                showDeliveryDetailsConstraint.priority = .defaultLow
                hideDeliveryDetailsConstraint.priority = .defaultHigh
                deliveryDetailsView.isHidden = true
            case .payPal:
                paymentMethodIconImageView.image = UIImage(named: "paypal-method")
            }
            paymentMethodIconImageView.isHidden = false
            paymentMethodLabel.isHidden = true
            paymentMethodTitleLabel.text = Constants.payingWithText
        }
        
        //shipping
        shippingMethodLabel.text = ""
        if let validCost = OrderManager.shared.validCost, let selectedShippingMethod = validCost.shippingMethod(id: OrderManager.shared.shippingMethod) {
            shippingMethodLabel.text = selectedShippingMethod.shippingCostFormatted
        }
        
        //address
        var addressString = ""
        if let address = OrderManager.shared.deliveryDetails?.address, let line1 = address.line1 {
            
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
    
    @IBAction public func itemAmountButtonPressed(_ sender: Any) {
        presentAmountPicker()
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
        
        if let selectedMethod = OrderManager.shared.shippingMethod, let cost = OrderManager.shared.validCost, let shippingMethod = cost.shippingMethod(id: selectedMethod) {
            payButtonText = payButtonText + " \(shippingMethod.totalCostFormatted)"
        }
        payButton.setTitle(payButtonText, for: .normal)
        
        let paymentMethod = OrderManager.shared.paymentMethod
        
        if paymentMethod == .applePay && PKPaymentAuthorizationViewController.canMakePayments() {
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
    
    private func presentAmountPicker() {
        let amountPickerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AmountPickerViewController") as! AmountPickerViewController
        amountPickerViewController.optionName = NSLocalizedString("Controllers/CheckoutViewController/ItemAmountPickerTitle",
                                                                              value: "Select amount",
                                                                              comment: "The title displayed on the picker view for the amount of basket items")
        amountPickerViewController.selectedValue = OrderManager.shared.itemCount
        amountPickerViewController.minimum = 1
        amountPickerViewController.maximum = 10
        amountPickerViewController.delegate = self
        amountPickerViewController.modalPresentationStyle = .overCurrentContext
        self.present(amountPickerViewController, animated: false, completion: nil)
    }
    
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifierDeliveryDetails, let vc = segue.destination as? DeliveryDetailsTableViewController {
            
        }
    }*/
    
    @IBAction private func applePayButtonTapped(_ sender: PKPaymentButton) {
        paymentManager.authorizePayment(cost: OrderManager.shared.cachedCost!, method: .applePay)
    }
    
    @IBAction func payButtonTapped(_ sender: UIButton) {
        
        var orderIsFree = false
        if let cost = OrderManager.shared.validCost, let selectedMethod = OrderManager.shared.shippingMethod, let shippingMethod = cost.shippingMethod(id: selectedMethod){
            orderIsFree = shippingMethod.totalCost == 0.0
        }
        
        checkDetailFields() //indicate to user if something is missing
        
        guard (!orderIsFree && OrderManager.shared.paymentMethod == .applePay) || (OrderManager.shared.deliveryDetails?.address?.isValid ?? false) else {
            //TODO: Indicate to the user that delivery information is missing
            return
        }
        
        guard orderIsFree || (OrderManager.shared.paymentMethod != nil && (OrderManager.shared.paymentMethod != .creditCard || Card.currentCard != nil)) else {
            //TODO: Indicate to the user that payment method is missing
            return
        }
        
        progressOverlayViewController.show(message: Constants.loadingPaymentText)
        OrderManager.shared.updateCost { [weak welf = self] (error: Error?) in
            self.progressOverlayViewController.hide()
            guard welf != nil else { return }
            guard let cost = OrderManager.shared.validCost, error == nil else {
                let genericError = NSLocalizedString("UpdateCostError", value: "An error occurred while updating our products.\nPlease try again later.", comment: "Generic error when retrieving the cost for the products in the basket")
                
                // TODO: show error to the user
                return
            }
            
            if let selectedMethod = OrderManager.shared.shippingMethod, let shippingMethod = cost.shippingMethod(id: selectedMethod), shippingMethod.totalCost == 0.0 {
                // The user must have a promo code which reduces this order cost to nothing, lucky user :)
                OrderManager.shared.paymentToken = nil
                welf?.submitOrder(completionHandler: nil)
            }
            else{
                if OrderManager.shared.paymentMethod == .applePay{
                    welf?.modalPresentationDismissedOperation = Operation()
                }
                
                guard let paymentMethod = OrderManager.shared.paymentMethod else { return }
                welf?.paymentManager.authorizePayment(cost: cost, method: paymentMethod)
            }
        }
    }
    
    //MARK: Order Summary Notifications
    
    @objc func orderSummaryPreviewImageReady() {
        updateItemImage()
    }
    
    //MARK: Keyboard
    
    @objc func keyboardWillChangeFrame(notification: Notification) {
        let userInfo = notification.userInfo
        guard let size = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        
        guard promoCodeTextField.isFirstResponder else { return }
        
        optionsViewTopConstraint.constant =  -size.height - promoCodeViewHeightConstraint.constant
        
        self.optionsViewBottomContraint.priority = .defaultLow
        self.optionsViewTopConstraint.priority = .defaultHigh
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: Notification){
        guard promoCodeTextField.isFirstResponder else { return }
        
        self.optionsViewBottomContraint.priority = .defaultHigh
        self.optionsViewTopConstraint.priority = .defaultLow
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func submitOrder(completionHandler: ((_ status: PKPaymentAuthorizationStatus) -> Void)?) {
        
        if let applePayDismissedOperation = modalPresentationDismissedOperation {
            self.transitionOperation.addDependency(applePayDismissedOperation)
        }
        completionHandler?(.success)
        
        OperationQueue.main.addOperation(transitionOperation)
    }
}

extension CheckoutViewController: AmountPickerDelegate {
    func amountPickerDidSelectValue(_ value: Int) {
        OrderManager.shared.itemCount = value
        itemAmountButton.setTitle("\(value)", for: .normal)
    }
}

extension CheckoutViewController: PaymentAuthorizationManagerDelegate {
    func costUpdated() {
        updateViews()
    }
    
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {
        if let error = error {
            // TODO: show the error to the user
            return
        }
        
        OrderManager.shared.paymentToken = token
        submitOrder(completionHandler: completionHandler)
    }
    
    func modalPresentationDidFinish() {
        OrderManager.shared.updateCost { [weak welf = self] (error: Error?) in
            guard welf != nil else { return }
            
            if let applePayDismissedOperation = welf?.modalPresentationDismissedOperation{
                if !applePayDismissedOperation.isFinished{
                    OperationQueue.main.addOperation(applePayDismissedOperation)
                }
            }
            
            if error != nil {
                // TODO: show the error to the user
                return
            }
        }
    }
    
}

extension CheckoutViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        OrderManager.shared.promoCode = textField.text
        refresh()
        
        textField.resignFirstResponder()
        return false
    }
}
