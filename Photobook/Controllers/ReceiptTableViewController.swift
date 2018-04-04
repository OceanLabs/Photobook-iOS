//
//  ReceiptTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import PassKit
import UserNotifications

struct ReceiptNotificationName {
    static let receiptWillDismiss = Notification.Name("ly.kite.sdk.receiptWillDismissNotificationName")
}

class ReceiptTableViewController: UITableViewController {
    
    private typealias State = ReceiptViewControllerState
    
    private struct Constants {
        static let loadingPaymentText = NSLocalizedString("Controllers/ReceiptTableViewController/PaymentLoadingText",
                                                          value: "Preparing Payment",
                                                          comment: "Info text displayed while preparing for payment service")
        static let loadingFinishingOrderText = NSLocalizedString("Controllers/ReceiptTableViewController/loadingFinishingOrderText",
                                                                 value: "Finishing order",
                                                                 comment: "Info text displayed while finishing order")
    }
    
    private enum Section: Int {
        case header, progress, info, details, lineItems, footer
    }
    
    var order: Order?
    
    private var cost: Cost? {
        return order?.cachedCost
    }
    
    private var state:State = .uploading {
        didSet {
            if state != oldValue {
                updateViews()
            }
        }
    }
    private var lastProcessingError:OrderProcessingError?
    
    @IBOutlet weak var dismissBarButtonItem: UIBarButtonItem!
    var dismissClosure:(() -> Void)?
    
    private var modalPresentationDismissedGroup = DispatchGroup()
    private lazy var paymentManager: PaymentAuthorizationManager = {
        let manager = PaymentAuthorizationManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(Analytics.ScreenName.receipt)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    
        updateViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(orderProcessingCompleted), name: OrderProcessingManager.Notifications.completed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderProcessingFailed(_:)), name: OrderProcessingManager.Notifications.failed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pendingUploadsChanged), name: OrderProcessingManager.Notifications.pendingUploadStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderProcessingWillFinish), name: OrderProcessingManager.Notifications.willFinishOrder, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let loadingString = NSLocalizedString("ReceiptTableViewController/LoadingData", value: "Loading info...", comment: "description for a loading indicator")
        emptyScreenViewController.show(message: loadingString, activity: true)
        
        if OrderProcessingManager.shared.isProcessingOrder {
            if state == .paymentFailed {
                //re entered screen from payment methods screen
                state = .paymentRetry
                emptyScreenViewController.hide(animated: true)
                return
            }
            
            //re entered app, load and resume upload
            ProductManager.shared.loadUserPhotobook()
            emptyScreenViewController.hide(animated: true)
        } else {
            //start processing
            OrderProcessingManager.shared.startProcessing()
            emptyScreenViewController.hide(animated: true)
            
            //ask for notification permission
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak welf = self] in
                welf?.notificationsSetup()
            })
        }

    }
    
    //MARK: Population
    
    private func updateViews() {
        tableView.reloadData()
        
        //dismiss button
        dismissBarButtonItem.title = state.dismissTitle
        dismissBarButtonItem.isEnabled = state.allowDismissing
        dismissBarButtonItem.tintColor = state.allowDismissing ? nil : .clear
    }
    
    //MARK: Actions
    
    @IBAction private func primaryActionButtonTapped(_ sender: UIBarButtonItem) {
        switch state {
        case .error:
            if let lastProcessingError = lastProcessingError {
                switch lastProcessingError {
                case .upload:
                    OrderProcessingManager.shared.startPhotobookUpload()
                    self.state = .uploading
                case .pdf, .submission:
                    OrderProcessingManager.shared.finishOrder()
                default: break
                }
            }
        case .paymentFailed:
            showPaymentMethods()
        case .paymentRetry:
            //re authorize payment and submit order again
            pay()
            break
        case .cancelled:
            dismiss()
        default: break
        }
    }
    
    @IBAction private func secondaryActionButtonTapped(_ sender: UIBarButtonItem) {
        if state == .paymentRetry {
            showPaymentMethods()
        }
    }

    @IBAction private func continueTapped(_ sender: UIBarButtonItem) {
        if state != .completed {
            let title = NSLocalizedString("ReceiptTableViewController/DismissAlertTitle", value: "Cancel Order?", comment: "Alert title when the user wants to close the upload/receipt screen")
            let message = NSLocalizedString("ReceiptTableViewController/DismissAlertMessage", value: "You have not been charged yet. Please note, if you cancel your design will be lost.", comment: "Alert message when the user wants to close the upload/receipt screen")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.no, style: .default, handler:nil))
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.yes, style: .destructive, handler: { [weak welf = self] (_) in
                welf?.dismiss()
            }))
            
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss()
        }
    }
    
    private func dismiss() {
        OrderProcessingManager.shared.cancelProcessing { [weak welf = self] in
            ProductManager.shared.reset()
            OrderManager.shared.reset()
            NotificationCenter.default.post(name: ReceiptNotificationName.receiptWillDismiss, object: nil)
            welf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            welf?.navigationController?.popToRootViewController(animated: true)
            welf?.dismissClosure?()
        }
    }
    
    private func pay() {
        guard let cost = cost else {
            return
        }
        
        if order?.paymentMethod == .applePay {
            modalPresentationDismissedGroup.enter()
        }
        
        guard let paymentMethod = order?.paymentMethod else { return }
        
        progressOverlayViewController.show(message: Constants.loadingPaymentText)
        paymentManager.authorizePayment(cost: cost, method: paymentMethod)
    }
    
    private func showPaymentMethods() {
        let paymentViewController = storyboard?.instantiateViewController(withIdentifier: "PaymentMethodsViewController") as! PaymentMethodsViewController
        navigationController?.pushViewController(paymentViewController, animated: true)
    }
    
    func proceedToTabBarController() {
        performSegue(withIdentifier: "ReceiptDismiss", sender: nil)
    }
    
    func notificationsSetup() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (success, error) in
            //don't care about the result
        }
    }
    
    //MARK: Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.header.rawValue:
            return 1
        case Section.progress.rawValue:
            return state == .uploading ? 1 : 0
        case Section.info.rawValue:
            return state == .uploading ? 0 : 1
        case Section.details.rawValue:
            if state == .cancelled { return 0 }
            return 1
        case Section.lineItems.rawValue:
            if state == .cancelled { return 0 }
            return cost?.lineItems?.count ?? 0
        case Section.footer.rawValue:
            if state == .cancelled { return 0 }
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.header.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptHeaderTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptHeaderTableViewCell
            
            cell.titleLabel.text = state.title
            
            return cell
        case Section.progress.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptProgressTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptProgressTableViewCell
            
            cell.updateProgress(pendingUploads: ProductManager.shared.pendingUploads, totalUploads: ProductManager.shared.totalUploads)
            cell.startProgressAnimation()
            
            return cell
        case Section.info.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptInfoTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptInfoTableViewCell
            
            cell.iconLabel.text = state.emoji
            cell.titleLabel.text = state.infoTitle
            cell.descriptionLabel.text = state.infoText
            cell.primaryActionButton.setTitle(state.primaryActionText, for: .normal)
            cell.secondaryActionButton.setTitle(state.secondaryActionText, for: .normal)
            cell.setActionButtonsHidden(state.actionsHidden)
            cell.setSecondaryActionButtonHidden(state.secondaryActionHidden)
            
            cell.primaryActionButton.addTarget(self, action: #selector(primaryActionButtonTapped(_:)), for: .touchUpInside)
            cell.secondaryActionButton.addTarget(self, action: #selector(secondaryActionButtonTapped(_:)), for: .touchUpInside)
            
            return cell
        case Section.details.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptDetailsTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptDetailsTableViewCell
            cell.shippingMethodLabel.text = cost?.shippingMethod(id: order?.shippingMethod)?.name
            
            cell.orderNumberLabel.alpha = 0.35
            switch state {
            case .uploading:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberPending", value: "Pending", comment: "Placeholder for order number while images are being uploaded")
            case .completed:
                if let orderId = order?.orderId {
                    cell.orderNumberLabel.text = "#\(orderId)"
                    cell.orderNumberLabel.alpha = 1
                } else {
                    cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberUnknown", value: "N/A", comment: "Placeholder for order number in the unlikely case when there is none")
                }
            case .error, .cancelled, .paymentFailed, .paymentRetry:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberFailed", value: "Failed", comment: "Placeholder for order number when image upload has failed")
            }
            
            let deliveryDetails = order?.deliveryDetails
            var addressString = ""
            if let name = deliveryDetails?.fullName, !name.isEmpty { addressString += "\(name)\n"}
            if let line1 = deliveryDetails?.address?.line1, !line1.isEmpty { addressString += "\(line1)\n"}
            if let line2 = deliveryDetails?.address?.line2, !line2.isEmpty { addressString += "\(line2)\n"}
            if let city = deliveryDetails?.address?.city, !city.isEmpty { addressString += "\(city) "}
            if let postCode = deliveryDetails?.address?.zipOrPostcode, !postCode.isEmpty { addressString += "\(postCode)\n"}
            if let countryName = deliveryDetails?.address?.country.name, !countryName.isEmpty { addressString += "\(countryName)\n"}
            cell.shippingAddressLabel.text = addressString
            
            return cell
        case Section.lineItems.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            cell.lineItemNameLabel.text = cost?.lineItems?[indexPath.row].name
            cell.lineItemCostLabel.text = cost?.lineItems?[indexPath.row].formattedCost
            return cell
        case Section.footer.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptFooterTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptFooterTableViewCell
            cell.totalCostLabel.text = cost?.shippingMethod(id: order?.shippingMethod)?.totalCostFormatted
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    //MARK: - Order Processing
    
    @objc func pendingUploadsChanged() {
        tableView.reloadData()
    }
    
    @objc func orderProcessingCompleted() {
        NotificationCenter.default.post(name: OrdersNotificationName.orderWasSuccessful, object: order)
        
        progressOverlayViewController.hide()
        state = .completed
    }

    @objc func orderProcessingFailed(_ notification: NSNotification) {
        //send a local notification
        let userNotification = UNMutableNotificationContent()
        
        //determine error
        if let error = notification.userInfo?["error"] as? OrderProcessingError {
            switch error {
            case .payment:
                state = .paymentFailed
                userNotification.title = NSLocalizedString("ReceiptTableViewController/NotificationTitlePaymentFailed", value: "Payment Failed", comment: "title of a notification notfifying about failed photobook payment")
                userNotification.body = NSLocalizedString("ReceiptTableViewController/NotificationBodyPaymentFailed", value: "Update your payment method to finish photobook checkout", comment: "body of a notification notfifying about failed photobook payment")
            case .cancelled:
                state = .cancelled
                userNotification.title = NSLocalizedString("ReceiptTableViewController/NotificationTitleCancelled", value: "Photobook Cancelled", comment: "title of a notification notfifying about failed photobook that had to be cancelled")
                userNotification.body = NSLocalizedString("ReceiptTableViewController/NotificationBodyCancelled", value: "Something went wrong and we couldn't process your photbook", comment: "body of a notification notfifying about failed photobook that had to be cancelled")
            default:
                state = .error
                userNotification.title = NSLocalizedString("ReceiptTableViewController/NotificationTitleProcessingFailed", value: "Couldn't Finish Photobook", comment: "title of a notification notfifying about failed photobook processing")
                userNotification.body = NSLocalizedString("ReceiptTableViewController/NotificationBodyProcessingFailed", value: "Something went wrong and your photobook couldn't be sent to our servers", comment: "body of a notification notfifying about failed photobook processing")
            }
            lastProcessingError = error
        }
        progressOverlayViewController.hide()
    
        //send local notification
        let request = UNNotificationRequest(identifier: "ReceiptTableViewController.OrderProcessingFailed", content: userNotification, trigger:nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    @objc func orderProcessingWillFinish() {
        progressOverlayViewController.show(message: Constants.loadingFinishingOrderText)
    }
    
}

extension ReceiptTableViewController : PaymentAuthorizationManagerDelegate {
    
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
        
        order?.paymentToken = token
        
        OrderProcessingManager.shared.finishOrder()
    }
    
    func modalPresentationDidFinish() {
        modalPresentationDismissedGroup.leave()
    }
    
}
