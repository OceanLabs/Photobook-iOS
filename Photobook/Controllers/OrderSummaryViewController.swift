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

class OrderSummaryViewController: UIViewController {
    
    private struct Constants {
        static let sectionDetails = 0
        static let sectionTotal = 1
        static let sectionOptions = 2
        
        static let dimensionsForCoverPhotoSnapshot: CGFloat = 100.0
        
        static let stringLoading = NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary")
        static let stringLoadingFail = NSLocalizedString("OrderSummary/LoadingFail", value: "Couldn't load order details", comment: "When loading order details fails")
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewImageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var previewImageProgressView: UIView!
    @IBOutlet weak var coverSnapshotPageView: PhotobookPageView!
    @IBOutlet weak var orderDetailsLabel: UILabel! { didSet { orderDetailsLabel.scaleFont() } }
    @IBOutlet weak var ctaButton: UIButton! { didSet { ctaButton.titleLabel?.scaleFont() } }
    @IBOutlet weak var loadingPreviewLabel: UILabel! { didSet { loadingPreviewLabel.scaleFont() } }
    
    var completionClosure: ((_ source: UIViewController, _ success: Bool) -> ())?
    var emptyScreenDismissGroup: DispatchGroup? = DispatchGroup()
    
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
    
    private let orderSummaryManager = OrderSummaryManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.summary)
        
        ctaButton.setTitle(PhotobookSDK.shared.ctaButtonTitle, for: .normal)
        
        emptyScreenViewController.show(message: Constants.stringLoading, activity: true)
        
        orderSummaryManager.templates = ProductManager.shared.products
        orderSummaryManager.product = ProductManager.shared.currentProduct
        orderSummaryManager.delegate = self
        
        emptyScreenDismissGroup?.enter()
        orderSummaryManager.getSummary()
        
        emptyScreenDismissGroup?.enter()
        takeCoverSnapshot { [weak welf = self] (image) in
            welf?.orderSummaryManager.coverPageSnapshotImage = image
            welf?.emptyScreenDismissGroup?.leave()
        }
        
        emptyScreenDismissGroup?.notify(queue: DispatchQueue.main, execute: { [weak welf = self] in
            welf?.emptyScreenViewController.hide(animated: true)
            welf?.emptyScreenDismissGroup = nil
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (navigationController?.navigationBar as? PhotobookNavigationBar)?.setBarType(.white)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let topInset: CGFloat
        if #available(iOS 11, *) {
            topInset = 0
        } else {
            topInset = navigationController?.navigationBar.frame.maxY ?? 0
        }
        tableView.contentInset = UIEdgeInsets(top: topInset, left: tableView.contentInset.left, bottom: tableView.contentInset.bottom, right: tableView.contentInset.right)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction func tappedCallToAction(_ sender: Any) {
        product.pigBaseUrl = orderSummaryManager.summary?.pigBaseUrl
        
        guard completionClosure != nil else {
            autoDismiss(true)
            return
        }
        
        let controllerToDismiss = isPresentedModally() ? navigationController! : self
        completionClosure?(controllerToDismiss, true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func timerTriggered(_ timer: Timer) {
        previewImageProgressView.isHidden = false
        previewImageActivityIndicatorView.startAnimating()
    }
    
    private func takeCoverSnapshot(_ completion: @escaping (UIImage?)->()) {
        coverSnapshotPageView.alpha = 1.0
        coverSnapshotPageView.pageIndex = 0
        coverSnapshotPageView.backgroundColor = .clear
        coverSnapshotPageView.frame.size = CGSize(width: Constants.dimensionsForCoverPhotoSnapshot, height: Constants.dimensionsForCoverPhotoSnapshot / product.photobookTemplate.coverAspectRatio)
        coverSnapshotPageView.productLayout = product.productLayouts.first
        coverSnapshotPageView.product = product
        coverSnapshotPageView.color = product.coverColor
        coverSnapshotPageView.setupTextBox(mode: .userTextOnly)
        
        if let asset = product.productLayouts.first?.asset {
            asset.image(size: CGSize(width: Constants.dimensionsForCoverPhotoSnapshot, height: Constants.dimensionsForCoverPhotoSnapshot), loadThumbnailFirst: false, progressHandler: nil, completionHandler: { [weak welf = self] (image, error) in
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
        let displayName = orderSummaryManager.upsellOptions![index].displayName
        cell.titleLabel?.text = displayName
        
        cell.accessibilityIdentifier = "upsellOption\(index)"
        
        let isOptionEnabled = orderSummaryManager.isUpsellOptionSelected(orderSummaryManager.upsellOptions![index])
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

extension OrderSummaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Constants.sectionDetails:
            if #available(iOS 11.0, *) {
                return UIFontMetrics.default.scaledValue(for: 35)
            } else {
                return 35
            }
        case Constants.sectionTotal:
            if #available(iOS 11.0, *) {
                return UIFontMetrics.default.scaledValue(for: 45)
            } else {
                return 45
            }
        case Constants.sectionOptions:
            if #available(iOS 11.0, *) {
                return UIFontMetrics.default.scaledValue(for: 63)
            } else {
                return 63
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == Constants.sectionOptions,
            let upsellOption = orderSummaryManager.upsellOptions?[indexPath.row] {
            
            //deselect options with same type as the one that is going to be selected because we can't apply, for instance, two conflicting size upgrades to a specific template
            let selectedSameTypeUpsellOptions = orderSummaryManager.selectedUpsellOptions.filter { (optionInCollection) -> Bool in
                return optionInCollection != upsellOption && optionInCollection.type == upsellOption.type
            }
            for option in selectedSameTypeUpsellOptions {
                if let row = orderSummaryManager.upsellOptions?.firstIndex(of: option) {
                    let optionIndexPath = IndexPath(row: row, section: Constants.sectionOptions)
                    (tableView.cellForRow(at: optionIndexPath) as? OrderSummaryUpsellTableViewCell)?.setEnabled(false)
                    orderSummaryManager.deselectUpsellOption(option)
                }
            }
            
            
            //handle changed upsell selection
            orderSummaryManager.toggleUpsellOption(upsellOption)
            progressOverlayViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"))
            
            if let cell = tableView.cellForRow(at: indexPath) as? OrderSummaryUpsellTableViewCell {
                tappedUpsellOption(for: cell, at: indexPath.row)
            }
            
            if orderSummaryManager.isUpsellOptionSelected(upsellOption) {
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
        guard let summary = orderSummaryManager.summary else {
            return 0
        }
        
        switch section {
        case Constants.sectionDetails:
            return summary.details.count
        case Constants.sectionTotal:
            return summary.details.count > 0 ? 1 : 0
        case Constants.sectionOptions:
            if let upsellOptions = orderSummaryManager.upsellOptions { return upsellOptions.count }
            else { return 0 }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Constants.sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel?.text = orderSummaryManager.summary?.details[indexPath.row].name
            cell.priceLabel?.text = orderSummaryManager.summary?.details[indexPath.row].price
            return cell
        case Constants.sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            cell.priceLabel.text = orderSummaryManager.summary!.total
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

extension OrderSummaryViewController: OrderSummaryManagerDelegate {

    func orderSummaryManagerWillUpdate() {
        previewImageView.image = nil
        
        // Don't show a loading view if the request takes less than 0.3 seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerTriggered(_:)), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
    }
    
    func orderSummaryManagerFailedToSetPreviewImageUrl() {
        hideProgressIndicator()
    }
    
    func orderSummaryManagerDidSetPreviewImageUrl() {
        let size = previewImageView.frame.size * UIScreen.main.scale
        
        orderSummaryManager.fetchPreviewImage(withSize: size) { [weak welf = self] (image) in
            welf?.previewImageView.image = image
            welf?.hideProgressIndicator()
        }
    }
    
    func orderSummaryManagerDidUpdate(_ summary: OrderSummary?, error: ErrorMessage?) {
        
        if orderSummaryManager.summary != nil {
            progressOverlayViewController.hide(animated: true)
            emptyScreenDismissGroup?.leave()
            
            let numberOfOptions = orderSummaryManager.upsellOptions?.count ?? 0
            let sectionsToUpdate = tableView.numberOfRows(inSection: 2) == numberOfOptions ? 0...1 : 0...2
            tableView.reloadSections(IndexSet(integersIn: sectionsToUpdate), with: .automatic)
        } else {
            hideProgressIndicator()
            
            let errorMessage = error ?? ErrorMessage(.generic)
            
            emptyScreenViewController.show(message: errorMessage.text, title: errorMessage.title, image: nil, activity: false, buttonTitle: CommonLocalizedStrings.retry, buttonAction: {
                self.emptyScreenViewController.show(message: Constants.stringLoading, activity: true)
                self.orderSummaryManager.getSummary()
            })
        }
    }
    
    func orderSummaryManagerFailedToApply(_ upsell: UpsellOption, error: ErrorMessage) {
        hideProgressIndicator()
        
        var offsetTop: CGFloat = 0
        
        if let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar {
            offsetTop = navigationBar.barHeight
        }
        MessageBarViewController.show(message: error, parentViewController: self, offsetTop: offsetTop, centred: true, dismissAfter: 3.0)
        
        if let selectedIndices = tableView.indexPathsForSelectedRows {
            for selectedIndex in selectedIndices {
                tableView.deselectRow(at: selectedIndex, animated: false)
            }
        }
        let sectionsToUpdate = Constants.sectionOptions...Constants.sectionOptions
        tableView.reloadSections(IndexSet(integersIn: sectionsToUpdate), with: .automatic)
    }
}
