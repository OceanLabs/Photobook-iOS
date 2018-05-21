//
//  OrderSummaryViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryViewController: UIViewController {
    
    private struct Constants {
        static let sectionDetails = 0
        static let sectionTotal = 1
        static let sectionOptions = 2
        
        static let stringLoading = NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary")
        static let stringLoadingFail = NSLocalizedString("OrderSummary/LoadingFail", value: "Couldn't load order details", comment: "When loading order details fails")
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewImageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var previewImageProgressView: UIView!
    @IBOutlet weak var coverSnapshotPageView: PhotobookPageView!
    
    private var timer: Timer?
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.summary)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryManagerWillUpdate), name: OrderSummaryManager.notificationWillUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryManagerDidUpdateSummary), name: OrderSummaryManager.notificationDidUpdateSummary, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryManagerPreviewImageReady), name: OrderSummaryManager.notificationPreviewImageReady, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryManagerPreviewImageFailed), name: OrderSummaryManager.notificationPreviewImageFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryManagerConnectionError), name: OrderSummaryManager.notificationConnectionError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orderSummaryManagerApplyUpsellFailed), name: OrderSummaryManager.notificationApplyUpsellFailed, object: nil)
        
        emptyScreenViewController.show(message: Constants.stringLoading, activity: true)
        
        OrderSummaryManager.shared.reset()
        
        takeCoverSnapshot { (image) in
            OrderSummaryManager.shared.coverPageSnapshotImage = image
            OrderSummaryManager.shared.refresh()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (navigationController?.navigationBar as? PhotobookNavigationBar)?.setBarType(.white)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OrderSummarySegueName" {
            
            // Add current item to the basket
            OrderManager.shared.basketOrder.products = [self.product] //We currently only support one item at a time
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func timerTriggered(_ timer: Timer) {
        previewImageProgressView.isHidden = false
        previewImageActivityIndicatorView.startAnimating()
    }
    
    private func takeCoverSnapshot(_ completion: @escaping (UIImage?)->()) {
        // Move this up to constants
        let dimensionForPage = 100.0 * UIScreen.main.scale
        
        coverSnapshotPageView.alpha = 1.0
        
        coverSnapshotPageView.pageIndex = 0
        coverSnapshotPageView.backgroundColor = .clear
        coverSnapshotPageView.frame.size = CGSize(width: dimensionForPage, height: dimensionForPage / product.template.aspectRatio)
        coverSnapshotPageView.productLayout = product.productLayouts.first
        
        coverSnapshotPageView.color = product.coverColor
        coverSnapshotPageView.setupTextBox(mode: .userTextOnly)
        
        if let asset = product.productLayouts.first?.asset {
            asset.image(size: CGSize(width: dimensionForPage, height: dimensionForPage), loadThumbnailFirst: false, progressHandler: nil, completionHandler: { [weak welf = self] (image, error) in
                guard let image = image else { return }
                
                welf?.coverSnapshotPageView.shouldSetImage = true
                welf?.coverSnapshotPageView.setupImageBox(with: image)
                let snapshot = welf?.coverSnapshotPageView.snapshot()
                completion(snapshot)
                welf?.coverSnapshotPageView.alpha = 0.0
            })
        } else {
            completion(coverSnapshotPageView.snapshot())
            self.coverSnapshotPageView.alpha = 0.0
        }
    }
    
    private func tappedUpsellOption(for cell: OrderSummaryUpsellTableViewCell, at index: Int) {
        let displayName = OrderSummaryManager.shared.upsellOptions![index].displayName
        cell.titleLabel?.text = displayName
        
        cell.accessibilityIdentifier = "upsellOption\(index)"
        
        let isOptionEnabled = OrderSummaryManager.shared.isUpsellOptionSelected(OrderSummaryManager.shared.upsellOptions![index])
        cell.setEnabled(isOptionEnabled)
        cell.accessibilityLabel = displayName
        if isOptionEnabled {
            cell.accessibilityValue = NSLocalizedString("Accessibility/Enabled", value: "Enabled", comment: "Informs the user that an upsell option is enabled.")
        } else {
            cell.accessibilityValue = NSLocalizedString("Accessibility/Disabled", value: "Disabled", comment: "Informs the user that an upsell option is disabled.")
        }
    }
    
    func hideProgressIndicator() {
        timer?.invalidate()
        previewImageActivityIndicatorView.stopAnimating()
        previewImageProgressView.isHidden = true
        progressOverlayViewController.hide(animated: true)
    }
    
}

//MARK: - Notifications
extension OrderSummaryViewController {
    
    @objc func orderSummaryManagerWillUpdate() {
        previewImageView.image = nil
        
        // Don't show a loading view if the request takes less than 0.3 seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerTriggered(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
    }
    
    @objc func orderSummaryManagerDidUpdateSummary() {
        progressOverlayViewController.hide(animated: true)
        
        if OrderSummaryManager.shared.summary != nil {
            emptyScreenViewController.hide(animated: true)
            
            let numberOfOptions = OrderSummaryManager.shared.upsellOptions?.count ?? 0
            let sectionsToUpdate = tableView.numberOfRows(inSection: 2) == numberOfOptions ? 0...1 : 0...2
            tableView.reloadSections(IndexSet(integersIn: sectionsToUpdate), with: .automatic)
        } else {
            
            emptyScreenViewController.show(message: Constants.stringLoadingFail, title: nil, image: nil, activity: false, buttonTitle: CommonLocalizedStrings.retry, buttonAction: {
                self.emptyScreenViewController.show(message: Constants.stringLoading, activity: true)
                OrderSummaryManager.shared.refresh()
            })
        }
    }
    
    @objc func orderSummaryManagerPreviewImageReady() {
        
        let scaleFactor = UIScreen.main.scale
        let size = CGSize(width: previewImageView.frame.size.width * scaleFactor, height: previewImageView.frame.size.height * scaleFactor)
        
        OrderSummaryManager.shared.fetchPreviewImage(withSize: size) { [weak welf = self] (image) in
            welf?.previewImageView.image = image
            
            welf?.hideProgressIndicator()
        }
    }
    
    @objc func orderSummaryManagerPreviewImageFailed() {
        hideProgressIndicator()
    }
    
    @objc func orderSummaryManagerConnectionError() {
        hideProgressIndicator()
        
        emptyScreenViewController.show(message: CommonLocalizedStrings.checkConnectionAndRetry, title: nil, image: nil, activity: false, buttonTitle: CommonLocalizedStrings.retry, buttonAction: {
            self.emptyScreenViewController.show(message: Constants.stringLoading, activity: true)
            OrderSummaryManager.shared.refresh()
        })
    }
    
    @objc func orderSummaryManagerApplyUpsellFailed() {
        hideProgressIndicator()
        
        //show message bar
        let message = ErrorMessage(text: NSLocalizedString("Controllers/OrderSummaryViewController/UpsellFailMessage", value: "Couldn't apply upsell option", comment: "An upsell uption couldn't be applied due to an unknown reason"))
        
        var offsetTop: CGFloat = 0
        
        if let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar {
            offsetTop = navigationBar.barHeight
        }
        MessageBarViewController.show(message: message, parentViewController: self, offsetTop: offsetTop, centred: true, dismissAfter: 3.0)
        
        if let selectedIndices = tableView.indexPathsForSelectedRows {
            for selectedIndex in selectedIndices {
                tableView.deselectRow(at: selectedIndex, animated: false)
            }
        }
        let sectionsToUpdate = Constants.sectionOptions...Constants.sectionOptions
        tableView.reloadSections(IndexSet(integersIn: sectionsToUpdate), with: .automatic)
    }
    
}

extension OrderSummaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Constants.sectionDetails:
            return 35
        case Constants.sectionTotal:
            return 45
        case Constants.sectionOptions:
            return 63
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == Constants.sectionOptions,
            let upsellOption = OrderSummaryManager.shared.upsellOptions?[indexPath.row] {
            
            //deselect options with same type as the one that is going to be selected because we can't apply, for instance, two conflicting size upgrades to a specific template
            let selectedSameTypeUpsellOptions = OrderSummaryManager.shared.selectedUpsellOptions.filter { (optionInCollection) -> Bool in
                return optionInCollection != upsellOption && optionInCollection.type == upsellOption.type
            }
            for option in selectedSameTypeUpsellOptions {
                if let row = OrderSummaryManager.shared.upsellOptions?.index(of: option) {
                    let optionIndexPath = IndexPath(row: row, section: Constants.sectionOptions)
                    (tableView.cellForRow(at: optionIndexPath) as? OrderSummaryUpsellTableViewCell)?.setEnabled(false)
                    OrderSummaryManager.shared.deselectUpsellOption(option)
                }
            }
            
            
            //handle changed upsell selection
            OrderSummaryManager.shared.toggleUpsellOption(upsellOption)
            progressOverlayViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"))
            
            if let cell = tableView.cellForRow(at: indexPath) as? OrderSummaryUpsellTableViewCell {
                tappedUpsellOption(for: cell, at: indexPath.row)
            }
            
            if OrderSummaryManager.shared.isUpsellOptionSelected(upsellOption) {
                Analytics.shared.trackAction(.selectedUpsellOption, [Analytics.PropertyNames.upsellOptionName: upsellOption.displayName])
            } else {
                Analytics.shared.trackAction(.deselectedUpsellOption, [Analytics.PropertyNames.upsellOptionName: upsellOption.displayName])
            }
        }
    }
    
}

extension OrderSummaryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let summary = OrderSummaryManager.shared.summary else {
            return 0
        }
        
        switch section {
        case Constants.sectionDetails:
            return summary.details.count
        case Constants.sectionTotal:
            return summary.details.count>0 ? 1 : 0
        case Constants.sectionOptions:
            if let upsellOptions = OrderSummaryManager.shared.upsellOptions { return upsellOptions.count }
            else { return 0 }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Constants.sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel.text = OrderSummaryManager.shared.summary?.details[indexPath.row].name
            cell.priceLabel.text = OrderSummaryManager.shared.summary?.details[indexPath.row].price
            return cell
        case Constants.sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            let summary = OrderSummaryManager.shared.summary!
            cell.priceLabel.text = summary.total
            return cell
        case Constants.sectionOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryUpsellTableViewCell", for: indexPath) as! OrderSummaryUpsellTableViewCell
            tappedUpsellOption(for: cell, at: indexPath.row)
            
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }
}
