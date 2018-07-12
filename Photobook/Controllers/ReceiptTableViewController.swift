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
        case header, progress, info, details, lineItems, shipping, footer
    }
    
    var order: Order!
    
    private var cost: Cost? {
        return order.cost
    }
    
    private var state: State = .uploading {
        didSet {
            if state != oldValue {
                updateViews()
            }
        }
    }
    private var lastProcessingError: OrderProcessingError?
    
    @IBOutlet weak var dismissBarButtonItem: UIBarButtonItem!
    var dismissClosure: ((UIViewController) -> Void)?
    weak var dismissDelegate: DismissDelegate?
    
    private var modalPresentationDismissedGroup = DispatchGroup()
    private lazy var paymentManager: PaymentAuthorizationManager = {
        let manager = PaymentAuthorizationManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (navigationController?.navigationBar as? PhotobookNavigationBar)?.setBarType(.clear)
        
        OrderManager.shared.orderProcessingDelegate = self
        
        Analytics.shared.trackScreenViewed(.receipt)
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if OrderManager.shared.isProcessingOrder {
            // Navigated back from payment methods screen
            if state == .paymentFailed {
                state = .paymentRetry
                return
            }

            // If we have an orderId, submission or polling might have failed
            if order.orderId != nil {
                OrderManager.shared.finishOrder()
                return
            }
            
            // Check if there are pending uploads for the current order
            OrderManager.shared.hasPendingUploads { [weak welf = self] (hasPendingTasks) in
                // Check if all assets have URLs. If so, finish the order. Continue uploading otherwise.
                if !hasPendingTasks && OrderManager.shared.processingOrder!.remainingAssetsToUpload().count == 0 {
                    OrderManager.shared.finishOrder()
                    welf?.tableView.reloadData()
                    return
                }
                
                welf?.state = .uploading
                OrderManager.shared.uploadAssets()
                welf?.tableView.reloadData()
            }
            return
        }

        // Start processing
        OrderManager.shared.startProcessing(order: order)
        
        // Ask for notification permission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak welf = self] in
            welf?.notificationsSetup()
        })
    }
    
    // MARK: - Population
    
    private func updateViews() {
        tableView.reloadData()
        
        // Dismiss button
        dismissBarButtonItem.title = state.dismissTitle
        dismissBarButtonItem.isEnabled = state.allowDismissing
    }
    
    // MARK: - Actions
    
    @IBAction private func primaryActionButtonTapped(_ sender: UIBarButtonItem) {
        switch state {
        case .error:
            if let lastProcessingError = lastProcessingError {
                switch lastProcessingError {
                case .upload:
                    state = .uploading
                    OrderManager.shared.uploadAssets()
                case .uploadProcessing, .submission, .api(message: _):
                    OrderManager.shared.finishOrder()
                default: break
                }
            }
        case .paymentFailed:
            showPaymentMethods()
        case .paymentRetry:
            //re authorize payment and submit order again
            Analytics.shared.trackAction(.uploadRetried)
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
                Analytics.shared.trackAction(.uploadCancelled)
                welf?.dismiss()
            }))
            
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss()
        }
    }
    
    private func dismiss() {
        OrderManager.shared.cancelProcessing { [weak welf = self] in
            ProductManager.shared.reset()
            OrderManager.shared.reset()
            NotificationCenter.default.post(name: ReceiptNotificationName.receiptWillDismiss, object: nil)
            
            
            #if PHOTOBOOK_SDK
            if welf?.dismissDelegate?.wantsToDismiss?(self) != nil {
                return
            }
            
            // No delegate or dismiss closure provided
            if welf?.presentingViewController != nil {
                welf?.presentingViewController!.dismiss(animated: true, completion: nil)
                return
            }
            welf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            welf?.navigationController?.popToRootViewController(animated: true)
            #else
            // Check if the Photobook app was launched into the ReceiptViewController
            if welf?.navigationController?.viewControllers.count == 1 {
                welf?.navigationController?.isNavigationBarHidden = true
                welf?.dismissClosure?(self)
            } else {
                welf?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                welf?.navigationController?.popToRootViewController(animated: true)
            }
            #endif
        }
    }
    
    private func pay() {
        guard let cost = cost else {
            return
        }
        
        if order.paymentMethod == .applePay {
            modalPresentationDismissedGroup.enter()
        }
        
        guard let paymentMethod = order.paymentMethod else { return }
        
        progressOverlayViewController.show(message: Constants.loadingPaymentText)
        paymentManager.authorizePayment(cost: cost, method: paymentMethod)
    }
    
    private func showPaymentMethods() {
        let paymentViewController = storyboard?.instantiateViewController(withIdentifier: "PaymentMethodsViewController") as! PaymentMethodsViewController
        navigationController?.pushViewController(paymentViewController, animated: true)
    }
    
    func notificationsSetup() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (success, error) in
                // Don't care about the result
            }
        } else {
            // iOS 9
            let type: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.alert, UIUserNotificationType.sound]
            let setting = UIUserNotificationSettings(types: type, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(setting)
        }
    }
    
    // MARK: Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.header.rawValue:
            return 1
        case Section.progress.rawValue:
            return state == .uploading ? 1 : 0
        case Section.info.rawValue:
            return state == .uploading ? 0 : 1
        case Section.lineItems.rawValue:
            if state == .cancelled { return 0 }
            return cost?.lineItems.count ?? 0
        case Section.shipping.rawValue, Section.details.rawValue, Section.footer.rawValue:
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
            
            let total = order.assetsToUpload().count
            cell.updateProgress(pendingUploads: order.remainingAssetsToUpload().count, totalUploads: total)
            cell.startProgressAnimation()
            
            return cell
        case Section.info.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptInfoTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptInfoTableViewCell
            
            if let error = lastProcessingError, case .api(message: let message) = error {
                let errorCopy = ReceiptViewControllerState.customErrorWith(message)
                cell.titleLabel.text = errorCopy.title
                cell.descriptionLabel.text = errorCopy.description
            } else {
                cell.titleLabel.text = state.infoTitle
                cell.descriptionLabel.text = state.infoText
            }
            cell.iconImageView.image = state.icon
            cell.primaryActionButton.setTitle(state.primaryActionText, for: .normal)
            cell.primaryActionButton.setTitleColor(state.primaryActionTitleColor, for: .normal)
            cell.primaryActionButton.backgroundColor = state.primaryActionBackgroundColor
            cell.secondaryActionButton.setTitle(state.secondaryActionText, for: .normal)
            cell.setActionButtonsHidden(state.actionsHidden)
            cell.setSecondaryActionButtonHidden(state.secondaryActionHidden)
            
            cell.primaryActionButton.addTarget(self, action: #selector(primaryActionButtonTapped(_:)), for: .touchUpInside)
            cell.secondaryActionButton.addTarget(self, action: #selector(secondaryActionButtonTapped(_:)), for: .touchUpInside)
            
            return cell
        case Section.details.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptDetailsTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptDetailsTableViewCell
            
            cell.orderNumberLabel.alpha = 0.35
            switch state {
            case .uploading:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberPending", value: "Pending", comment: "Placeholder for order number while images are being uploaded")
            case .completed:
                if let orderId = order.orderId {
                    cell.orderNumberLabel.text = "#\(orderId)"
                    cell.orderNumberLabel.alpha = 1
                } else {
                    cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberUnknown", value: "N/A", comment: "Placeholder for order number in the unlikely case when there is none")
                }
            case .error, .cancelled, .paymentFailed, .paymentRetry:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberFailed", value: "Failed", comment: "Placeholder for order number when image upload has failed")
            }
            
            let deliveryDetails = order.deliveryDetails
            var addressString = ""
            if let name = deliveryDetails?.fullName, !name.isEmpty { addressString += "\(name)\n"}
            if let line1 = deliveryDetails?.address?.line1, !line1.isEmpty { addressString += "\(line1)\n"}
            if let line2 = deliveryDetails?.address?.line2, !line2.isEmpty { addressString += "\(line2)\n"}
            if let city = deliveryDetails?.address?.city, !city.isEmpty { addressString += "\(city) "}
            if let postCode = deliveryDetails?.address?.zipOrPostcode, !postCode.isEmpty { addressString += "\(postCode)\n"}
            if let countryName = deliveryDetails?.address?.country.name, !countryName.isEmpty { addressString += "\(countryName)"}
            cell.shippingAddressLabel.text = addressString
            
            return cell
        case Section.lineItems.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            cell.lineItemNameLabel.text = cost?.lineItems[indexPath.row].name
            cell.lineItemCostLabel.text = cost?.lineItems[indexPath.row].price.formatted
            return cell
        case Section.shipping.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            cell.lineItemNameLabel.text = CommonLocalizedStrings.shipping
            cell.lineItemCostLabel.text = cost?.totalShippingPrice.formatted
            return cell
        case Section.footer.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptFooterTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptFooterTableViewCell
            cell.totalCostLabel.text = cost?.total.formatted
            return cell
        default:
            return UITableViewCell()
        }
    }
}

extension ReceiptTableViewController: PaymentAuthorizationManagerDelegate {
    
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
        
        OrderManager.shared.finishOrder()
    }
    
    func modalPresentationDidFinish() {
        modalPresentationDismissedGroup.leave()
    }
}

extension ReceiptTableViewController: OrderProcessingDelegate {
    
    func orderDidComplete(error: OrderProcessingError?) {
        
        guard error == nil else {

            var notificationTitle: String?
            var notificationBody: String?
            
            // Determine error
            switch error! {
            case .payment:
                state = .paymentFailed
                notificationTitle = NSLocalizedString("ReceiptTableViewController/NotificationTitlePaymentFailed", value: "Payment Failed", comment: "title of a notification notifying about failed photobook payment")
                notificationBody = NSLocalizedString("ReceiptTableViewController/NotificationBodyPaymentFailed", value: "Update your payment method to finish photobook checkout", comment: "body of a notification notifying about failed photobook payment")
            case .cancelled:
                state = .cancelled
                notificationTitle = NSLocalizedString("ReceiptTableViewController/NotificationTitleCancelled", value: "Photobook Cancelled", comment: "title of a notification notifying about failed photobook that had to be cancelled")
                notificationBody = NSLocalizedString("ReceiptTableViewController/NotificationBodyCancelled", value: "Something went wrong and we couldn't process your photo book", comment: "body of a notification notifying about failed photobook that had to be cancelled")
            case .api(message: let errorMessage):
                state = .error
                notificationTitle = errorMessage.title?.uppercased() ?? CommonLocalizedStrings.somethingWentWrong.uppercased()
                notificationBody = errorMessage.text
            default:
                state = .error
                notificationTitle = NSLocalizedString("ReceiptTableViewController/NotificationTitleProcessingFailed", value: "Couldn't Finish Photobook", comment: "title of a notification notifying about failed photobook processing")
                notificationBody = NSLocalizedString("ReceiptTableViewController/NotificationBodyProcessingFailed", value: "Something went wrong and your photo book couldn't be sent to our servers", comment: "body of a notification notifying about failed photobook processing")
            }
            
            lastProcessingError = error
            progressOverlayViewController.hide()
            
            // Send local notification
            guard let title = notificationTitle, let body = notificationBody else { return }
            
            if #available(iOS 10.0, *) {
                let userNotification = UNMutableNotificationContent()
                userNotification.title = title
                userNotification.body = body
                userNotification.badge = 1
                let request = UNNotificationRequest(identifier: "ReceiptTableViewController.OrderProcessingFailed", content: userNotification, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            } else {
                // ios 9
                let notification = UILocalNotification()
                notification.alertTitle = title
                notification.alertBody = body
                notification.fireDate = Date()
                notification.applicationIconBadgeNumber = 1
                notification.soundName = UILocalNotificationDefaultSoundName
                UIApplication.shared.cancelAllLocalNotifications()
                UIApplication.shared.scheduleLocalNotification(notification)
            }

            return
        }
        
        // Completed
        order.lastSubmissionDate = Date()
        NotificationCenter.default.post(name: OrdersNotificationName.orderWasSuccessful, object: order)
        
        progressOverlayViewController.hide()
        state = .completed
    }
    
    func uploadStatusDidUpdate() {
        tableView.reloadData()
    }
    
    func orderWillFinish() {
        progressOverlayViewController.show(message: Constants.loadingFinishingOrderText)
    }
}
