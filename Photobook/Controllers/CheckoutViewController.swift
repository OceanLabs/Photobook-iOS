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
    
    private let segueIdentifierDeliveryDetails = "segueDeliveryDetails"
    private let segueIdentifierShippingMethods = "segueShippingMethods"
    private let segueIdentifierPaymentMethods = "seguePaymentMethods"
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemAmountLabel: UILabel!
    
    @IBOutlet weak var promoCodeView: UIView!
    @IBOutlet weak var promoCodeTextField: UITextField!
    @IBOutlet weak var deliveryDetailsView: UIView!
    @IBOutlet weak var deliveryDetailsLabel: UILabel!
    @IBOutlet weak var shippingMethodView: UIView!
    @IBOutlet weak var shippingMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodView: UIView!
    @IBOutlet weak var paymentMethodIconImageView: UIImageView!
    @IBOutlet weak var payButtonContainerView: UIView!
    @IBOutlet weak var payButton: UIButton!
    private var applePayButton: PKPaymentButton?
    private var payButtonOriginalColor:UIColor!
    
    
    @IBOutlet weak var optionsViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var optionsViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var promoCodeViewHeightConstraint: NSLayoutConstraint!
    
    private var paymentViewController:PaymentViewController!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()
        
        paymentViewController = PaymentViewController()
        
        payButtonOriginalColor = payButton.backgroundColor
        
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        populate()
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func populate() {
        
        //product
        
        itemTitleLabel.text = ProductManager.shared.product?.name
        itemPriceLabel.text = OrderManager.shared.cachedCost?.lineItems?.first?.formattedCost
        
        //payment method icon
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
            case .payPal:
                paymentMethodIconImageView.image = UIImage(named: "paypal-method")
            }
        }
        
        //shipping
        shippingMethodLabel.text = ""
        if let validCost = OrderManager.shared.validCost, let selectedShippingMethod = validCost.shippingMethod(id: OrderManager.shared.shippingMethod) {
            shippingMethodLabel.text = selectedShippingMethod.totalCostFormatted
        }
        
        //address
        var addressString = ""
        if let address = OrderManager.shared.deliveryDetails?.address, let line1 = address.line1 {
            
            addressString = line1
            if let line2 = address.line2, !line2.isEmpty { addressString = addressString + ", " + line2 }
            if let postcode = address.zipOrPostcode, !postcode.isEmpty { addressString = addressString + ", " + postcode }
            if !address.country.name.isEmpty { addressString = addressString + ", " + address.country.name }
        }
        deliveryDetailsLabel.text = addressString
        
        adaptPayButton()
    }
    
    func adaptPayButton() {
        //hide all
        applePayButton?.isHidden = true
        applePayButton?.isEnabled = false
        payButton.isHidden = true
        payButton.isEnabled = false
        
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
    
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifierDeliveryDetails, let vc = segue.destination as? DeliveryDetailsTableViewController {
            
        }
    }*/
    
    @IBAction private func deliveryDetailsTapped(_ sender: UITapGestureRecognizer) {
        //performSegue(withIdentifier: Constants.addressSegueName, sender: nil)
    }
    
    @IBAction private func shippingMethodTapped(_ sender: UITapGestureRecognizer) {
        //performSegue(withIdentifier: "ShippingMethodsSegue", sender: nil)
    }
    
    @IBAction private func paymentMethodTapped(_ sender: UITapGestureRecognizer) {
        //performSegue(withIdentifier: Constants.paymentMethodsSegueName, sender: nil)
    }
    
    @IBAction private func applePayButtonTapped(_ sender: PKPaymentButton) {
        
        
        
        paymentViewController.payTapped(sender)
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
}

extension CheckoutViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return false
    }
}
