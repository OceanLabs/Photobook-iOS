//
//  OrderSummaryViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryViewController: UIViewController {
    
    private let sectionDetails = 0
    private let sectionTotal = 1
    private let sectionOptions = 2
    
    private let stringLoading = NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary")
    private let stringLoadingFail = NSLocalizedString("OrderSummary/LoadingFail", value: "Couldn't load order details", comment: "When loading order details fails")
    private let stringLoadingRetry = NSLocalizedString("OrderSummary/LoadingFailRetry", value: "Retry", comment: "Retry button title when loading order details fails")
    private let stringTitle = NSLocalizedString("OrderSummary/Title", value: "Your order", comment: "Title of the screen that displays order details and upsell options")
    
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
    
    var orderSummaryManager:OrderSummaryManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = stringTitle
        
        emptyScreenViewController.show(message: stringLoading, activity: true)
        
        orderSummaryManager = OrderSummaryManager(withDelegate: self)
        
        takeCoverSnapshot { (image) in
            self.orderSummaryManager.coverPageSnapshotImage = image
            self.orderSummaryManager.refresh()
        }
    }
    
    @objc private func timerTriggered(_ timer: Timer) {
        previewImageProgressView.isHidden = false
        previewImageActivityIndicatorView.startAnimating()
    }
    
    private func takeCoverSnapshot(_ completion: @escaping (UIImage)->()) {
        // Move this up to constants
        let dimensionForPage = 100.0 * UIScreen.main.scale
        
        coverSnapshotPageView.alpha = 1.0
        
        coverSnapshotPageView.pageIndex = 0
        coverSnapshotPageView.backgroundColor = .clear
        coverSnapshotPageView.frame.size = CGSize(width: dimensionForPage, height: dimensionForPage / ProductManager.shared.product!.aspectRatio)
        coverSnapshotPageView.productLayout = ProductManager.shared.productLayouts.first
        
        coverSnapshotPageView.color = ProductManager.shared.coverColor
        coverSnapshotPageView.setupTextBox(mode: .userTextOnly)
        
        if let asset = ProductManager.shared.productLayouts.first?.asset {
            asset.image(size: CGSize(width: dimensionForPage, height: dimensionForPage), loadThumbnailsFirst: false, completionHandler: { (image, error) in
                guard let image = image else { return }
                
                self.coverSnapshotPageView.setupImageBox(with: image)
                completion(self.coverSnapshotPageView.snapshot())
                self.coverSnapshotPageView.alpha = 0.0
            })
        } else {
            completion(coverSnapshotPageView.snapshot())
            self.coverSnapshotPageView.alpha = 0.0
        }
    }
    
}

extension OrderSummaryViewController: OrderSummaryManagerDelegate {
    func orderSummaryManagerWillUpdate(_ manager: OrderSummaryManager) {
        previewImageView.image = nil
        
        // Don't show a loading view if the request takes less than 0.3 seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerTriggered(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
    }
    
    func orderSummaryManager(_ manager: OrderSummaryManager, didUpdateSummary success: Bool) {
        progressOverlayViewController.hide(animated: true)
        
        if success {
            emptyScreenViewController.hide(animated: true)
            tableView.reloadData()
        } else {
            
            emptyScreenViewController.show(message: stringLoadingFail, title: nil, image: nil, activity: false, buttonTitle: stringLoadingRetry, buttonAction: {
                self.emptyScreenViewController.show(message: self.stringLoading, activity: true)
                self.orderSummaryManager.refresh()
            })
        }
    }
    
    func orderSummaryManager(_ manager: OrderSummaryManager, didUpdatePreviewImage success:Bool) {
        self.previewImageView.image = manager.previewImage
        
        timer?.invalidate()
        previewImageProgressView.isHidden = true
        previewImageActivityIndicatorView.stopAnimating()
    }
    
    func orderSummaryManagerSizeForPreviewImage(_ manager: OrderSummaryManager) -> CGSize {
        let scaleFactor = UIScreen.main.scale
        return CGSize(width: previewImageView.frame.size.width * scaleFactor, height: previewImageView.frame.size.height * scaleFactor)
    }
}

extension OrderSummaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case sectionDetails:
            return 35
        case sectionTotal:
            return 45
        case sectionOptions:
            return 63
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            orderSummaryManager.selectUpsellOption(orderSummaryManager.upsellOptions![indexPath.row])
            progressOverlayViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"))
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            orderSummaryManager.deselectUpsellOption(orderSummaryManager.upsellOptions![indexPath.row])
            progressOverlayViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"))
        }
    }
}

extension OrderSummaryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let summary = orderSummaryManager.summary else {
            return 0
        }
        
        switch section {
        case sectionDetails:
            return summary.details.count
        case sectionTotal:
            return summary.details.count>0 ? 1 : 0
        case sectionOptions:
            if let upsellOptions = orderSummaryManager.upsellOptions { return upsellOptions.count }
            else { return 0 }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel.text = orderSummaryManager.summary?.details[indexPath.row].name
            cell.priceLabel.text = orderSummaryManager.summary?.details[indexPath.row].price
            return cell
        case sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            let summary = orderSummaryManager.summary!
            cell.priceLabel.text = summary.total
            return cell
        case sectionOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryUpsellTableViewCell", for: indexPath) as! OrderSummaryUpsellTableViewCell
            cell.titleLabel?.text = orderSummaryManager.upsellOptions![indexPath.row].displayName
            if orderSummaryManager.isUpsellOptionSelected(orderSummaryManager.upsellOptions![indexPath.row]) {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }
}
