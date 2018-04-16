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
        
        emptyScreenViewController.show(message: Constants.stringLoading, activity: true)
        
        takeCoverSnapshot { (image) in
            OrderSummaryManager.shared.coverPageSnapshotImage = image
            OrderSummaryManager.shared.refresh()
        }
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
            tableView.reloadData()
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
            
            welf?.timer?.invalidate()
            welf?.previewImageProgressView.isHidden = true
            welf?.previewImageActivityIndicatorView.stopAnimating()
        }
    }
    
    @objc func orderSummaryManagerPreviewImageFailed() {
        self.timer?.invalidate()
        self.previewImageProgressView.isHidden = true
        self.previewImageActivityIndicatorView.stopAnimating()
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
        if indexPath.section == Constants.sectionOptions,
            let upsellOption = OrderSummaryManager.shared.upsellOptions?[indexPath.row] {
            //handle changed upsell selection
            OrderSummaryManager.shared.selectUpsellOption(upsellOption)
            progressOverlayViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"))
            Analytics.shared.trackAction(.selectedUpsellOption, [Analytics.PropertyNames.upsellOptionName: upsellOption.displayName])
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == Constants.sectionOptions,
            let upsellOption = OrderSummaryManager.shared.upsellOptions?[indexPath.row] {
            //handle changed upsell selection
            OrderSummaryManager.shared.deselectUpsellOption(upsellOption)
            progressOverlayViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"))
            Analytics.shared.trackAction(.deselectedUpsellOption, [Analytics.PropertyNames.upsellOptionName: upsellOption.displayName])
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
            cell.titleLabel?.text = OrderSummaryManager.shared.upsellOptions![indexPath.row].displayName
            if OrderSummaryManager.shared.isUpsellOptionSelected(OrderSummaryManager.shared.upsellOptions![indexPath.row]) {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }
}
