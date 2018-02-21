//
//  PaymentViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import PassKit

class PaymentViewController: UIViewController {
    
    private struct Constants {
        static let receiptSegueName = "ReceiptSegue"
    }
    
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

    
    @IBAction func payTapped(_ sender: UIButton) {
        
        var orderIsFree = false
        if let cost = OrderManager.shared.validCost, let selectedMethod = OrderManager.shared.shippingMethod, let shippingMethod = cost.shippingMethod(id: selectedMethod){
            orderIsFree = shippingMethod.totalCost == 0.0
        }
        
        guard (!orderIsFree && OrderManager.shared.paymentMethod == .applePay) || (OrderManager.shared.deliveryDetails?.address?.isValid ?? false) else {
            // TODO: Indicate to the user that delivery information is missing
            return
        }
        
        guard orderIsFree || (OrderManager.shared.paymentMethod != nil && (OrderManager.shared.paymentMethod != .creditCard || Card.currentCard != nil)) else {
            // TODO: Indicate to the user that payment method is missing
            return
        }
        
        OrderManager.shared.updateCost { [weak welf = self] (error: Error?) in
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
    
    private func submitOrder(completionHandler: ((_ status: PKPaymentAuthorizationStatus) -> Void)?) {
        
        if let applePayDismissedOperation = modalPresentationDismissedOperation {
            transitionOperation.addDependency(applePayDismissedOperation)
        }
        completionHandler?(.success)
        
        OperationQueue.main.addOperation(transitionOperation)
    }
    
    private func updateViews() {
        // TODO: update views
    }
    
}

extension PaymentViewController: PaymentAuthorizationManagerDelegate {
    //MARK: Payment Authorization Manager Delegate
    
    func paymentAuthorizationDidFinish(token: String?, error: Error?, completionHandler: ((PKPaymentAuthorizationStatus) -> Void)?) {
        if let error = error {
            print(error)
            // TODO: show the error to the user
            return
        }
        
        OrderManager.shared.paymentToken = token
        submitOrder(completionHandler: completionHandler)
    }
    
    func costUpdated() {
        updateViews()
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
