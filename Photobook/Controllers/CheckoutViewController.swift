//
//  CheckoutViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 16/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

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
    @IBOutlet weak var shippingMethodView: UIView!
    @IBOutlet weak var shippingAddressLabel: UILabel!
    @IBOutlet weak var paymentMethodView: UIView!
    @IBOutlet weak var paymentMethodIconImageView: UIImageView!
    @IBOutlet weak var payButton: UIButton!
    
    
    @IBOutlet weak var optionsViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var optionsViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var promoCodeViewHeightConstraint: NSLayoutConstraint!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func adaptPayButton() {
        
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
