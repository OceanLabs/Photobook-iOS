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
import UserNotifications
import Stripe

struct ReceiptNotificationName {
    static let receiptWillDismiss = Notification.Name("ly.kite.sdk.receiptWillDismissNotificationName")
}

class ReceiptViewController: UIViewController {
    
    private typealias State = ReceiptViewControllerState
    
    private struct Constants {
        static let loadingPaymentText = NSLocalizedString("Controllers/ReceiptViewController/PaymentLoadingText",
                                                          value: "Preparing Payment",
                                                          comment: "Info text displayed while preparing for payment service")
        static let loadingFinishingOrderText = NSLocalizedString("Controllers/ReceiptViewController/loadingFinishingOrderText",
                                                                 value: "Finishing order",
                                                                 comment: "Info text displayed while finishing order")
    }
    
    private enum Section: Int {
        case header, progress, info, details, lineItems, shipping, promocode, footer
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
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var dismissBarButtonItem: UIBarButtonItem!
    var dismissClosure: ((UIViewController, Bool) -> Void)?
    
    private var modalPresentationDismissedGroup = DispatchGroup()
    private lazy var paymentManager: PaymentAuthorizationManager = {
        let manager = PaymentAuthorizationManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    private var redirectContext: STPRedirectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (navigationController?.navigationBar as? PhotobookNavigationBar)?.setBarType(.clear)
        
        OrderManager.shared.orderProcessingDelegate = self
        
        Analytics.shared.trackScreenViewed(.receipt)
        
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    
        updateViews()
        
        paymentManager.stripeHostViewController = self
        
        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(paymentAuthorized(_:)), name: PaymentNotificationName.authorized, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController == nil {
            fatalError("PhotobookViewController: Please use a navigation controller or alternatively, set the 'embedInNavigation' parameter to true.")
        }

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
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    @objc func paymentAuthorized(_ notification: NSNotification) {
        guard let parameters = notification.userInfo as? [String: String],
            let paymentIntentId = parameters["payment_intent"] else {
                state = .paymentRetry
                tableView.reloadData()
                return
        }
        
        order.paymentToken = paymentIntentId
        OrderManager.shared.finishOrder()
    }
    
    // MARK: - Population
    
    private func updateViews() {
        tableView.reloadData()
        
        // Dismiss button
        dismissBarButtonItem.title = state.dismissTitle
        dismissBarButtonItem.isEnabled = state.allowDismissing
    }
    
    // MARK: - Actions
    
    @IBAction private func primaryActionButtonTapped(_ sender: UIButton) {
        switch state {
        case .error:
            if let lastProcessingError = lastProcessingError {
                switch lastProcessingError {
                case .upload:
                    Analytics.shared.trackAction(.uploadRetried)
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
            // Re-authorise payment and submit order again
            Analytics.shared.trackAction(.paymentRetried)
            pay()
        case .cancelled:
            dismiss(success: false)
        default:
            break
        }
    }
    
    @IBAction private func secondaryActionButtonTapped(_ sender: UIButton) {
        if state == .paymentRetry {
            showPaymentMethods()
        }
    }

    @IBAction private func continueTapped(_ sender: UIBarButtonItem) {
        if state != .completed {
            let title = NSLocalizedString("ReceiptViewController/DismissAlertTitle", value: "Cancel Order?", comment: "Alert title when the user wants to close the upload/receipt screen")
            let message = NSLocalizedString("ReceiptViewController/DismissAlertMessage", value: "You have not been charged yet. Please note, if you cancel your design will be lost.", comment: "Alert message when the user wants to close the upload/receipt screen")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.no, style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.yes, style: .destructive, handler: { [weak welf = self] (_) in
                Analytics.shared.trackAction(.uploadCancelled)
                welf?.dismiss(success: false)
            }))
            
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss(success: true)
        }
    }
    
    private func dismiss(success: Bool) {
        OrderManager.shared.cancelProcessing { [weak welf = self] in
            ProductManager.shared.reset()
            OrderManager.shared.reset()            
            
            guard let stelf = welf else { return }
            if let gestureRecognizer = stelf.navigationController?.interactivePopGestureRecognizer {
                gestureRecognizer.isEnabled = true
            }
            guard stelf.dismissClosure != nil else {
                stelf.autoDismiss(true)
                return
            }
            let controllerToDismiss = stelf.isPresentedModally() ? stelf.navigationController! : stelf
            stelf.dismissClosure?(controllerToDismiss, success)
        }
    }
    
    private func pay() {
        guard let cost = cost, let paymentMethod = order.paymentMethod else { return }
        
        if paymentMethod == .applePay {
            modalPresentationDismissedGroup.enter()
        }
        
        progressOverlayViewController.show(message: Constants.loadingPaymentText)
        paymentManager.authorizePayment(cost: cost, method: paymentMethod)
    }
    
    private func showPaymentMethods() {
        let paymentViewController = storyboard?.instantiateViewController(withIdentifier: "PaymentMethodsViewController") as! PaymentMethodsViewController
        paymentViewController.paymentManager = paymentManager
        paymentViewController.order = order
        navigationController?.pushViewController(paymentViewController, animated: true)
    }
    
    func notificationsSetup() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (success, error) in
            // Don't care about the result
        }
    }
}

extension ReceiptViewController: PaymentAuthorizationManagerDelegate {
    
    func paymentAuthorizationRequiresAction(withContext context: STPRedirectContext) {
        redirectContext = context
        redirectContext?.startRedirectFlow(from: self)
    }
    
    func paymentAuthorizationManagerDidUpdateDetails() {}
    
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

extension ReceiptViewController: OrderProcessingDelegate {
    
    func orderDidComplete(error: OrderProcessingError?) {
        
        guard error == nil else {

            var notificationTitle: String?
            var notificationBody: String?
            
            // Determine error
            switch error! {
            case .payment:
                state = .paymentFailed
                notificationTitle = NSLocalizedString("ReceiptViewController/NotificationTitlePaymentFailed", value: "Payment Failed", comment: "title of a notification notifying about failed order payment")
                notificationBody = NSLocalizedString("ReceiptViewController/NotificationBodyPaymentFailed", value: "Update your payment method to finish order checkout", comment: "body of a notification notifying about failed order payment")
            case .cancelled:
                state = .cancelled
                notificationTitle = NSLocalizedString("ReceiptViewController/NotificationTitleCancelled", value: "Order Cancelled", comment: "title of a notification notifying about failed order that had to be cancelled")
                notificationBody = NSLocalizedString("ReceiptViewController/NotificationBodyCancelled", value: "Something went wrong and we couldn't process your order", comment: "body of a notification notifying about failed order that had to be cancelled")
            case .api(message: let errorMessage):
                state = .error
                notificationTitle = errorMessage.title?.uppercased() ?? CommonLocalizedStrings.somethingWentWrongTitle.uppercased()
                notificationBody = errorMessage.text
            default:
                state = .error
                notificationTitle = NSLocalizedString("ReceiptViewController/NotificationTitleProcessingFailed", value: "Couldn't Finish Order", comment: "title of a notification notifying about failed order processing")
                notificationBody = NSLocalizedString("ReceiptViewController/NotificationBodyProcessingFailed", value: "Something went wrong and your order couldn't be sent to our servers", comment: "body of a notification notifying about failed order processing")
            }
            
            lastProcessingError = error
            progressOverlayViewController.hide()
            
            // Send local notification
            guard let title = notificationTitle, let body = notificationBody else { return }
            
            let userNotification = UNMutableNotificationContent()
            userNotification.title = title
            userNotification.body = body
            userNotification.badge = 1
            let request = UNNotificationRequest(identifier: "ReceiptViewController.OrderProcessingFailed", content: userNotification, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

            return
        }
        
        // Completed
        order.lastSubmissionDate = Date()
        NotificationCenter.default.post(name: OrdersNotificationName.orderWasSuccessful, object: order)
        
        progressOverlayViewController.hide()
        state = .completed
    }
    
    func progressDidUpdate() {
        let indexPath = IndexPath(row: 0, section: Section.progress.rawValue)
        guard let cell = tableView.cellForRow(at: indexPath) as? ReceiptProgressTableViewCell else { return }
        cell.updateProgress(OrderManager.shared.uploadProgress, pendingUploads: order.remainingAssetsToUpload().count, totalUploads: order.assetsToUpload().count)        
    }
    
    func uploadStatusDidUpdate() {
        tableView.reloadData()
    }
    
    func orderWillFinish() {
        progressOverlayViewController.show(message: Constants.loadingFinishingOrderText)
    }
}

extension ReceiptViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        case Section.promocode.rawValue:
            if state == .cancelled || order.cost?.promoDiscount == nil { return 0 }
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.header.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptHeaderTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptHeaderTableViewCell
            
            cell.titleLabel.text = state.title
            
            return cell
        case Section.progress.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptProgressTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptProgressTableViewCell
            
            cell.updateProgress(OrderManager.shared.uploadProgress, pendingUploads: order.remainingAssetsToUpload().count, totalUploads: order.assetsToUpload().count)
            
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
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptViewController/OrderNumberPending", value: "Pending", comment: "Placeholder for order number while images are being uploaded")
            case .completed:
                if let orderId = order.orderId {
                    cell.orderNumberLabel.text = "#\(orderId)"
                    cell.orderNumberLabel.alpha = 1
                } else {
                    cell.orderNumberLabel.text = NSLocalizedString("ReceiptViewController/OrderNumberUnknown", value: "N/A", comment: "Placeholder for order number in the unlikely case when there is none")
                }
            case .error, .cancelled, .paymentFailed, .paymentRetry:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptViewController/OrderNumberFailed", value: "Failed", comment: "Placeholder for order number when image upload has failed")
            }
            
            let deliveryDetails = order.deliveryDetails
            var addressString = ""
            if let name = deliveryDetails?.fullName, !name.isEmpty { addressString += "\(name)\n"}
            if let line1 = deliveryDetails?.line1, !line1.isEmpty { addressString += "\(line1)\n"}
            if let line2 = deliveryDetails?.line2, !line2.isEmpty { addressString += "\(line2)\n"}
            if let city = deliveryDetails?.city, !city.isEmpty { addressString += "\(city) "}
            if let postCode = deliveryDetails?.zipOrPostcode, !postCode.isEmpty { addressString += "\(postCode)\n"}
            if let countryName = deliveryDetails?.country.name, !countryName.isEmpty { addressString += "\(countryName)"}
            cell.shippingAddressLabel.text = addressString
            
            return cell
        case Section.lineItems.rawValue:
            guard indexPath.row < min(order.cost?.lineItems.count ?? 0, order.products.count) else { return UITableViewCell() }
            
            let product = order.products[indexPath.row]
            guard let lineItem = order.lineItem(for: product) else { return UITableViewCell() }

            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            let quantityPrefix = "\(product.itemCount) x "
            cell.lineItemNameLabel.text = lineItem.name.hasPrefix(quantityPrefix) ? lineItem.name : "\(product.itemCount) x \(lineItem.name)"
            cell.lineItemCostLabel.text = lineItem.price.formatted
            return cell
        case Section.shipping.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            cell.lineItemNameLabel.text = CommonLocalizedStrings.shipping
            cell.lineItemCostLabel.text = cost?.totalShippingPrice.formatted
            return cell
        case Section.promocode.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            cell.lineItemNameLabel.text = NSLocalizedString("ReceiptViewController/Promotion", value: "Promotion", comment: "Label for the discounted amount")
            cell.lineItemCostLabel.text = "-" + cost!.promoDiscount!.formatted
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
