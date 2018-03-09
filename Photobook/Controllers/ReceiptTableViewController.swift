//
//  ReceiptTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct ReceiptNotificationName {
    static let receiptWillDismiss = Notification.Name("receiptWillDismissNotificationName")
}

class ReceiptTableViewController: UITableViewController {
    
    enum Section: Int {
        case header, progress, info, details, lineItems, footer
    }
    
    enum State: Int {
        case uploading
        case error
        case completed
        case cancelled
        case paymentFailed
    }
    
    var cost: Cost? {
        return OrderManager.shared.cachedCost
    }
    
    var state:State = .uploading {
        didSet {
            if state != oldValue {
                updateViews()
            }
        }
    }
    
    @IBOutlet weak var dismissBarButtonItem: UIBarButtonItem!
    var dismissClosure:(() -> Void)?
    
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
        
        let loadingString =  NSLocalizedString("ReceiptTableViewController/LoadingData", value: "Loading info...", comment: "description for a loading indicator")
        emptyScreenViewController.show(message: loadingString, activity: true)
        
        if ProductManager.shared.isUploading {
            //load and resume upload
            ProductManager.shared.loadUserPhotobook {}
            self.emptyScreenViewController.hide(animated: true)
        } else {
            //start upload
            ProductManager.shared.startPhotobookUpload { (totalUploads, error) in
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
        case .paymentFailed:
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/TitlePaymentFailed", value: "Payment Failed", comment: "Receipt sceen title if payment fails and payment method has to be updated")
        }
    }
    
    private func configure(infoCell cell:ReceiptInfoTableViewCell, forState state:State) {
        switch state {
        case .completed:
            cell.iconImageView.image = UIImage(named: "emoji-thumbsup")
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/InfoTitleCompleted", value: "Ready to Print", comment: "Status title if order has been completed and product is ready to print").uppercased()
            cell.descriptionLabel.text = NSLocalizedString("ReceiptTableViewController/InfoDescriptionCompleted", value: "We have received your photos and we will begin processing your photobook shortly", comment: "Info text when order has been completed")
            cell.setActionButtonHidden(true)
        case .error:
            cell.iconImageView.image = UIImage(named: "emoji-anxious")
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/InfoTitleError", value: "Something Went Wrong!", comment: "Status title if order couldn't be completed").uppercased()
            cell.descriptionLabel.text = NSLocalizedString("ReceiptTableViewController/InfoDescriptionError", value: "Something happened and we can't receive your photos at this point. You can retry or cancel and be refunded", comment: "Info text when order couldn't be completed")
            cell.actionButton.setTitle(NSLocalizedString("ReceiptTableViewController/InfoButtonError", value: "Retry", comment: "Info button text when order couldn't be completed").uppercased(), for: .normal)
            cell.setActionButtonHidden(false)
        case .cancelled:
            cell.iconImageView.image = UIImage(named: "cancelled")
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/InfoTitleCancelled", value: "Order Cancelled", comment: "Status title if was cancelled").uppercased()
            cell.descriptionLabel.text = NSLocalizedString("ReceiptTableViewController/InfoDescriptionCancelled", value: "Something happened and we can't receive your photos at this point but we haven't charged you anything", comment: "Info text when order couldn't be completed")
            cell.actionButton.setTitle(NSLocalizedString("ReceiptTableViewController/InfoButtonCancelled", value: "OK", comment: "Info button when order was cancelled").uppercased(), for: .normal)
            cell.setActionButtonHidden(true)
        case .paymentFailed:
            cell.iconImageView.image = Card.currentCard?.cardIcon
            cell.titleLabel.text = NSLocalizedString("ReceiptTableViewController/InfoTitlePaymentFailed", value: "Your Payment Method Failed", comment: "Payment has failed").uppercased()
            cell.descriptionLabel.text = NSLocalizedString("ReceiptTableViewController/InfoDescriptionPaymentFailed", value: "The charge for your book was declined.\nYou can retry with another method", comment: "Info text when payment method has failed")
            cell.actionButton.setTitle(NSLocalizedString("ReceiptTableViewController/InfoButtonPaymentFailed", value: "Update", comment: "Info button when payment has failed and payment method can be updated").uppercased(), for: .normal)
            cell.setActionButtonHidden(false)
        default: break
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
        case .paymentFailed:
            dismissBarButtonItem.isEnabled = true
            dismissBarButtonItem.tintColor = nil
            dismissBarButtonItem.title = failString
        }
    }
    
    //MARK: Actions
    
    @IBAction private func actionButtonTapped(_ sender: UIBarButtonItem) {
        switch state {
        case .error:
            ProductManager.shared.cancelPhotobookUpload {
                ProductManager.shared.startPhotobookUpload({ (count, error) in
                    self.state = .uploading
                })
            }
        case .paymentFailed:
        //TODO: push payment method screen
            break
        case .cancelled:
            dismiss()
        default: break
        }
    }

    @IBAction private func continueTapped(_ sender: UIBarButtonItem) {
        if state == .error {
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
            ProductManager.shared.reset()
            OrderManager.shared.reset()
            NotificationCenter.default.post(name: ReceiptNotificationName.receiptWillDismiss, object: nil)
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            self.navigationController?.popToRootViewController(animated: true)
            self.dismissClosure?()
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
            cell.actionButton.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
            
            return cell
        case Section.details.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptDetailsTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptDetailsTableViewCell
            cell.shippingMethodLabel.text = cost?.shippingMethod(id: OrderManager.shared.shippingMethod)?.name
            
            cell.orderNumberLabel.alpha = 0.5
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
            case .error, .cancelled, .paymentFailed:
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
        state = .uploading
        tableView.reloadData()
    }
    
    @objc func photobookUploadFinished() {
        //Create PDF
        progressOverlayViewController.show(message: "")
        ProductManager.shared.createPhotobookPdf { [weak welf = self] (urls, error) in
            guard let urls = urls else {
                if let error = error {
                    print("ReceiptTableViewController: \(error.localizedDescription)")
                }
                welf?.progressOverlayViewController.hide()
                welf?.state = .error //notify user about submission problem and provide option to retry
                return
            }
            
            //Submit Order
            OrderManager.shared.submitOrder(urls) { [weak welf = self] (errorMessage) in
                if let errorMessage = errorMessage {
                    print("ReceiptTableViewController: \(errorMessage.message)")
                    welf?.progressOverlayViewController.hide()
                    welf?.state = .error
                    return
                }
                welf?.progressOverlayViewController.hide()
                welf?.state = .completed
            }
        }
    }

    @objc func photobookUploadFailed() {
        state = .cancelled
    }
    
    @objc func shouldRetryUpload() {
        self.state = .error
    }
    
}
