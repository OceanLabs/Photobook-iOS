//
//  ReceiptTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import PassKit

struct ReceiptNotificationName {
    static let receiptWillDismiss = Notification.Name("receiptWillDismissNotificationName")
}

class ReceiptTableViewController: UITableViewController {
    
    struct Constants {
        static let saveIsProcessingKey = "ReceiptTableViewController.isProcessingOrder"
        
        static let infoTitleCompleted = NSLocalizedString("ReceiptTableViewController/InfoTitleCompleted", value: "Ready to Print", comment: "Status title if order has been completed and product is ready to print")
        static let infoDescriptionCompleted = NSLocalizedString("ReceiptTableViewController/InfoDescriptionCompleted", value: "We have received your photos and we will begin processing your photobook shortly", comment: "Info text when order has been completed")
        static let infoTitleError = NSLocalizedString("ReceiptTableViewController/InfoTitleError", value: "Something Went Wrong!", comment: "Status title if order couldn't be completed")
        static let infoDescriptionError = NSLocalizedString("ReceiptTableViewController/InfoDescriptionError", value: "Something happened and we can't receive your photos at this point. You can retry or cancel and be refunded", comment: "Info text when order couldn't be completed")
        static let infoTitleCancelled = NSLocalizedString("ReceiptTableViewController/InfoTitleCancelled", value: "Order Cancelled", comment: "Status title if was cancelled")
        static let infoDescriptionCancelled = NSLocalizedString("ReceiptTableViewController/InfoDescriptionCancelled", value: "Something happened and we can't receive your photos at this point but we haven't charged you anything", comment: "Info text when order couldn't be completed")
        static let infoTitlePaymentFailed = NSLocalizedString("ReceiptTableViewController/InfoTitlePaymentFailed", value: "Your Payment Method Failed", comment: "Payment has failed")
        static let infoDescriptionPaymentFailed = NSLocalizedString("ReceiptTableViewController/InfoDescriptionPaymentFailed", value: "The charge for your book was declined.\nYou can retry with another method", comment: "Info text when payment method has failed")
        
        static let loadingPaymentText = NSLocalizedString("Controllers/ReceiptTableViewController/PaymentLoadingText",
                                                          value: "Preparing Payment",
                                                          comment: "Info text displayed while preparing for payment service")
        
        static let infoButtonTitleRetry = NSLocalizedString("ReceiptTableViewController/InfoButtonRetry", value: "Retry", comment: "Info button text when order couldn't be completed")
        static let infoButtonTitleOK = NSLocalizedString("ReceiptTableViewController/InfoButtonCancelled", value: "OK", comment: "Info button when order was cancelled")
        static let infoButtonTitleUpdate = NSLocalizedString("ReceiptTableViewController/InfoButtonPaymentFailed", value: "Update", comment: "Info button when payment has failed and payment method can be updated")
    }
    
    enum Section: Int {
        case header, progress, info, details, lineItems, footer
    }
    
    enum State: Int {
        case uploading
        case error
        case completed
        case cancelled
        case paymentFailed
        case paymentRetry
    }
    
    var cost: Cost? {
        return OrderManager.shared.cachedCost
    }
    
    var state:State = .error {
        didSet {
            if state != oldValue {
                updateViews()
            }
        }
    }
    
    static var isProcessingOrder:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.saveIsProcessingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.saveIsProcessingKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBOutlet weak var dismissBarButtonItem: UIBarButtonItem!
    var dismissClosure:(() -> Void)?
    
    private var modalPresentationDismissedGroup = DispatchGroup()
    lazy private var paymentManager: PaymentAuthorizationManager = {
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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    
        OrderManager.shared.loadBackup()
        updateViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(pendingUploadsChanged), name: ProductManager.pendingUploadStatusUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photobookUploadFinished), name: ProductManager.finishedPhotobookUpload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(photobookUploadFailed), name: ProductManager.failedPhotobookUpload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldRetryUpload), name: ProductManager.shouldRetryUploadingImages, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let loadingString = NSLocalizedString("ReceiptTableViewController/LoadingData", value: "Loading info...", comment: "description for a loading indicator")
        emptyScreenViewController.show(message: loadingString, activity: true)
        
        if ReceiptTableViewController.isProcessingOrder {
            if state == .paymentFailed {
                //re entered screen from payment methods screen
                state = .paymentRetry
                self.emptyScreenViewController.hide(animated: true)
                return
            }
            
            //re entered app, load and resume upload
            ProductManager.shared.loadUserPhotobook {
                
            }
            self.emptyScreenViewController.hide(animated: true)
        } else {
            //start processing
            ReceiptTableViewController.isProcessingOrder = true
            //start upload
            ProductManager.shared.startPhotobookUpload { (totalUploads, error) in
                self.state = .uploading
                if totalUploads == 0, error == nil {
                    self.state = .error
                }
                self.emptyScreenViewController.hide(animated: true)
            }
        }

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Population
    
    private func updateViews() {
        tableView.reloadData()
        configure(dismissButtonForState: state)
    }
    
    private func configure(headerCell cell:ReceiptHeaderTableViewCell, forState state:State) {
        switch state {
        case .uploading:
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/TitleUploading", value: "Processing Order", comment: "Receipt sceen title when uploading images")
        case .completed:
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/TitleCompleted", value: "Order Complete", comment: "Receipt sceen title when successfully completed uploading images and order is confirmed")
        case .error:
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/TitleError", value: "Upload Failed", comment: "Receipt sceen title when uploading images fails")
        case .cancelled:
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/TitleCancelled", value: "Order Cancelled", comment: "Receipt sceen title if order had to be cancelled because of unresolvable technical problems")
        case .paymentFailed, .paymentRetry:
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/TitlePaymentFailed", value: "Payment Failed", comment: "Receipt sceen title if payment fails and payment method has to be updated")
        }
    }
    
    private func configure(infoCell cell:ReceiptInfoTableViewCell, forState state:State) {
        switch state {
        case .completed:
            cell.iconImageView.image = UIImage(named: "emoji-thumbsup")
            cell.titleLabel.text = Constants.infoTitleCompleted.uppercased()
            cell.descriptionLabel.text = Constants.infoDescriptionCompleted
            cell.setActionButtonsHidden(true)
        case .error:
            cell.iconImageView.image = UIImage(named: "emoji-anxious")
            cell.titleLabel.text = Constants.infoTitleError.uppercased()
            cell.descriptionLabel.text = Constants.infoDescriptionError
            cell.primaryActionButton.setTitle(Constants.infoButtonTitleRetry.uppercased(), for: .normal)
            cell.setActionButtonsHidden(false)
        case .cancelled:
            cell.iconImageView.image = UIImage(named: "cancelled")
            cell.titleLabel.text = Constants.infoTitleCancelled.uppercased()
            cell.descriptionLabel.text = Constants.infoDescriptionCancelled
            cell.primaryActionButton.setTitle(Constants.infoButtonTitleOK.uppercased(), for: .normal)
            cell.setActionButtonsHidden(true)
        case .paymentFailed, .paymentRetry:
            cell.iconImageView.image = UIImage(named: "generic-method")
            cell.titleLabel.text = Constants.infoTitlePaymentFailed.uppercased()
            cell.descriptionLabel.text = Constants.infoDescriptionPaymentFailed
            cell.primaryActionButton.setTitle(Constants.infoButtonTitleUpdate.uppercased(), for: .normal)
            cell.setActionButtonsHidden(false)
        default: break
        }
        
        if state == .paymentRetry {
            cell.setSecondaryActionButtonHidden(false)
            cell.primaryActionButton.setTitle(Constants.infoButtonTitleRetry.uppercased(), for: .normal)
            cell.secondaryActionButton.setTitle(Constants.infoButtonTitleUpdate.uppercased(), for: .normal)
        } else {
            cell.setSecondaryActionButtonHidden(true)
        }
    }
    
    private func configure(dismissButtonForState state:State) {
        let successString = NSLocalizedString("ReceiptTableViewController/DismissButtonSuccess", value: "Continue", comment: "Button displayed after order was placed successfully")
        let failString = NSLocalizedString("ReceiptTableViewController/DismissButtonFail", value: "Cancel", comment: "Button displayed when something has gone wrong and order couldn't be placed. This gives the user the option to cancel the upload and purchase")
        switch state {
        case .uploading:
            dismissBarButtonItem.isEnabled = false
            dismissBarButtonItem.tintColor = .clear
        case .completed:
            dismissBarButtonItem.isEnabled = true
            dismissBarButtonItem.tintColor = nil
            dismissBarButtonItem.title = successString
        case .error:
            dismissBarButtonItem.isEnabled = true
            dismissBarButtonItem.tintColor = nil
            dismissBarButtonItem.title = failString
        case .cancelled:
            dismissBarButtonItem.isEnabled = true
            dismissBarButtonItem.tintColor = nil
            dismissBarButtonItem.title = failString
        case .paymentFailed, .paymentRetry:
            dismissBarButtonItem.isEnabled = true
            dismissBarButtonItem.tintColor = nil
            dismissBarButtonItem.title = failString
        }
    }
    
    //MARK: Actions
    
    @IBAction private func primaryActionButtonTapped(_ sender: UIBarButtonItem) {
        switch state {
        case .error:
            ProductManager.shared.cancelPhotobookUpload {
                ProductManager.shared.startPhotobookUpload({ (count, error) in
                    self.state = .uploading
                })
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
        ProductManager.shared.cancelPhotobookUpload {
            ReceiptTableViewController.isProcessingOrder = false
            ProductManager.shared.reset()
            OrderManager.shared.reset()
            NotificationCenter.default.post(name: ReceiptNotificationName.receiptWillDismiss, object: nil)
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            self.navigationController?.popToRootViewController(animated: true)
            self.dismissClosure?()
        }
    }
    
    private func pay() {
        guard let cost = cost else {
            return
        }
        
        if OrderManager.shared.paymentMethod == .applePay {
            modalPresentationDismissedGroup.enter()
        }
        
        guard let paymentMethod = OrderManager.shared.paymentMethod else { return }
        
        progressOverlayViewController.show(message: Constants.loadingPaymentText)
        paymentManager.authorizePayment(cost: cost, method: paymentMethod)
    }
    
    private func showPaymentMethods() {
        let paymentViewController = storyboard?.instantiateViewController(withIdentifier: "PaymentMethodsViewController") as! PaymentMethodsViewController
        navigationController?.pushViewController(paymentViewController, animated: true)
    }
    
    private func createPDFs(_ completion: @escaping (_ urls:[String]?, _ error:Error?) -> Void) {
        ProductManager.shared.createPhotobookPdf { [weak welf = self] (urls, error) in
            guard let urls = urls else {
                if let error = error {
                    print("ReceiptTableViewController: \(error.localizedDescription)")
                }

                welf?.state = .error //notify user about submission problem and provide option to retry
 
                completion(nil, error)
                return
            }
            
            completion(urls, error)
        }
    }
    
    private func submitOrder(_ urls:[String], completion: @escaping (_ errorMessage:ErrorMessage?) -> Void) {
        OrderManager.shared.submitOrder(urls) { [weak welf = self] (errorMessage) in
            if let errorMessage = errorMessage {
                welf?.state = .error
                completion(errorMessage)
                return
            }
            
            //TODO: check for order success
            welf?.pollOrderSuccess(completion: { (errorMessage) in
            })
            
            welf?.state = .completed
            completion(errorMessage)
        }
    }
    
    private func pollOrderSuccess(completion: @escaping (_ errorMessage:ErrorMessage?) -> Void) {
        //TODO: poll order success and provide option to change payment method if fails
        completion(nil)
    }
    
    private func finishOrder() {
        //Create PDF
        progressOverlayViewController.show(message: "")
        createPDFs { [weak welf = self] (urls, error) in
            if let urls = urls {
                welf?.submitOrder(urls, completion: { (errorMessage) in
                    if let errorMessage = errorMessage {
                        print("ReceiptTableViewController: \(errorMessage.message)")
                    }
                    welf?.progressOverlayViewController.hide()
                })
            } else {
                //failure
                welf?.progressOverlayViewController.hide()
            }
        }
    }
    
    //MARK: Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if state == .cancelled {
            if section == Section.details.rawValue || section == Section.footer.rawValue || section == Section.lineItems.rawValue {
                return 0
            }
        }
        if section == Section.progress.rawValue {
            return state == .uploading ? 1 : 0
        }
        if section == Section.info.rawValue {
            return state == .uploading ? 0 : 1
        }
        if section == Section.lineItems.rawValue {
            return cost?.lineItems?.count ?? 0
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.header.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptHeaderTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptHeaderTableViewCell
            
            configure(headerCell: cell, forState: state)
            
            return cell
        case Section.progress.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptProgressTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptProgressTableViewCell
            
            cell.updateProgress(pendingUploads: ProductManager.shared.pendingUploads, totalUploads: ProductManager.shared.totalUploads)
            cell.startProgressAnimation()
            
            return cell
        case Section.info.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptInfoTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptInfoTableViewCell
            
            configure(infoCell: cell, forState: state)
            cell.primaryActionButton.addTarget(self, action: #selector(primaryActionButtonTapped(_:)), for: .touchUpInside)
            cell.secondaryActionButton.addTarget(self, action: #selector(secondaryActionButtonTapped(_:)), for: .touchUpInside)
            
            return cell
        case Section.details.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptDetailsTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptDetailsTableViewCell
            cell.shippingMethodLabel.text = cost?.shippingMethod(id: OrderManager.shared.shippingMethod)?.name
            
            cell.orderNumberLabel.alpha = 0.35
            switch state {
            case .uploading:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberPending", value: "Pending", comment: "Placeholder for order number while images are being uploaded")
            case .completed:
                if let orderId = OrderManager.shared.orderId {
                    cell.orderNumberLabel.text = "#\(orderId)"
                    cell.orderNumberLabel.alpha = 1
                } else {
                    cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberUnknown", value: "N/A", comment: "Placeholder for order number in the unlikely case when there is none")
                }
            case .error, .cancelled, .paymentFailed, .paymentRetry:
                cell.orderNumberLabel.text = NSLocalizedString("ReceiptTableViewController/OrderNumberFailed", value: "Failed", comment: "Placeholder for order number when image upload has failed")
            }
            
            let deliveryDetails = OrderManager.shared.deliveryDetails
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
            cell.totalCostLabel.text = cost?.shippingMethod(id: OrderManager.shared.shippingMethod)?.totalCostFormatted
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    //MARK: - Upload
    
    @objc func pendingUploadsChanged() {
        if state == .cancelled { // don't allow uploads if cancelled, cancel existing uploads instead
            ProductManager.shared.cancelPhotobookUpload {}
            return
        }
        state = .uploading
        tableView.reloadData()
    }
    
    @objc func photobookUploadFinished() {
        finishOrder()
    }

    @objc func photobookUploadFailed() {
        ProductManager.shared.cancelPhotobookUpload {
            self.state = .cancelled
            ReceiptTableViewController.isProcessingOrder = false
        }
    }
    
    @objc func shouldRetryUpload() {
        self.state = .error
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
        
        OrderManager.shared.paymentToken = token
        
        finishOrder()
    }
    
    func modalPresentationDidFinish() {
        modalPresentationDismissedGroup.leave()
    }
    
}
