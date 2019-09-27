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

protocol PhotobookAssetsDelegate: class {
    var assets: [Asset]! { get set }
}

class PhotobookViewController: UIViewController, PhotobookNavigationBarDelegate, PhotobookAssetsDelegate {
    
    var photobookNavigationBarType: PhotobookNavigationBarType = .clear
    
    /// Array of Assets to populate the pages of the photobook.
    var assets: [Asset]!
    
    /// Delegate that can provide a custom asset picker
    weak var photobookDelegate: PhotobookDelegate?
    
    /// Closure to call when a photobook has been created or needs to be dismissed
    var completionClosure: ((_ source: UIViewController, _ success: Bool) -> ())?
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    private struct Constants {
        static let titleArrowOffset: CGFloat = -8.0
        static let rearrangeScale: CGFloat = 0.8
        static let cellSideMargin: CGFloat = 10.0
        static let rearrangeAnimationDuration: TimeInterval = 0.25
        static let dragLiftScale: CGFloat = 1.1
        static let autoScrollTopScreenThreshold: CGFloat = 0.2
        static let autoScrollBottomScreenThreshold: CGFloat = 0.9
        static let autoScrollOffset: CGFloat = 10.0
        static let dragLiftAnimationDuration: TimeInterval = 0.15
        static let dropAnimationDuration: TimeInterval = 0.3
        static let proposalCellHeight: CGFloat = 30.0
        static let ctaButtonVerticalMargin: CGFloat = 15.0
    }
    private var reverseRearrangeScale: CGFloat {
        return 1.0 / Constants.rearrangeScale
    }

    @IBOutlet private weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ctaButton: UIButton! { didSet { ctaButton.titleLabel?.scaleFont() } }
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var ctaButtonContainer: UIView!
    @IBOutlet private var backButton: UIButton?
    @IBOutlet private weak var ctaButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ctaButtonContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ctaButtonContainerBottomConstraint: NSLayoutConstraint!
    
    private lazy var cancelBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tappedCancel(_:)))
    }()
    
    private var titleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        button.titleLabel?.scaleFont()
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(namedInPhotobookBundle:"chevron-down"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: Constants.titleArrowOffset)
        button.addTarget(self, action: #selector(didTapOnTitle), for: .touchUpInside)
        button.accessibilityIdentifier = "titleButton"
        return button
    }()

    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    private var interactingItemIndexPath: IndexPath?
    private var proposedDropIndexPath: IndexPath?
    private var insertingIndexPath: IndexPath?
    private var isRearranging = false
    private var draggingView: UIView?
    private var isDragging = false
    private weak var currentlyPanningGesture: UIPanGestureRecognizer?
    private var scrollingTimer: Timer?
    private var timerBlock: (() -> Void)?
    
    // Scrolling at 60Hz when we are dragging looks good enough and avoids having to normalize the scroll offset
    private lazy var screenRefreshRate: Double = 1.0 / 60.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.photobook)
        setup()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController == nil {
            fatalError("PhotobookViewController: Please use a navigation controller or alternatively, set the 'embedInNavigation' parameter to true.")
        }
        
        updateNavBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        adjustInsets()
        adjustButtonLabels()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func adjustButtonLabels() {
        titleButton.titleLabel?.sizeToFit()
        titleButton.sizeToFit()
        ctaButton.titleLabel?.sizeToFit()
    }
    
    private func adjustInsets() {
        let insets: UIEdgeInsets
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
        } else {
            insets = .zero
        }
        
        let normalTopInset: CGFloat
        let multiplier: CGFloat
        if #available(iOS 11, *) {
            normalTopInset = 0
            multiplier = 1 - Constants.rearrangeScale
            
            navigationItem.largeTitleDisplayMode = .never
            ctaButtonHeightConstraint.constant = UIFontMetrics.default.scaledValue(for: 50)
            ctaButtonContainerHeightConstraint.constant = ctaButtonHeightConstraint.constant + Constants.ctaButtonVerticalMargin * 2.0 + view.safeAreaInsets.bottom
        } else {
            normalTopInset = navigationController?.navigationBar.frame.maxY ?? 0
            multiplier = 1 + Constants.rearrangeScale
        }
        
        let bottomInset = ctaButtonContainerHeightConstraint.constant - insets.bottom - collectionViewBottomConstraint.constant
        
        let rearrangingTopInset = (navigationController?.navigationBar.frame.maxY ?? 0) * multiplier
        
        collectionView.contentInset = UIEdgeInsets(top: isRearranging ? rearrangingTopInset : normalTopInset, left: collectionView.contentInset.left, bottom: isRearranging ? 0.0 : bottomInset, right: collectionView.contentInset.right)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
    }
    
    private func setup() {
        collectionViewBottomConstraint.constant = -view.frame.height * (reverseRearrangeScale - 1)
        
        navigationItem.hidesBackButton = true
        
        if let tabBar = tabBarController?.tabBar { tabBar.isHidden = true }
    
        if isPresentedModally() {
            navigationItem.leftBarButtonItems = [ cancelBarButtonItem ]
        } else {
            backButton?.setTitleColor(navigationController?.navigationBar.tintColor, for: .normal)
        }
        
        // Remove pasteboard so that we avoid edge-cases with stale or inconsistent data
        UIPasteboard.remove(withName: UIPasteboard.Name("ly.kite.photobook.rearrange"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereUpdated(_:)), name: AssetsNotificationName.albumsWereUpdated, object: nil)
        
        if ProductManager.shared.products == nil {
            loadProducts()
            return
        }
        setupProduct()
    }
    
    private func setupProduct() {
        if let product = product, let _ = assets {
            setup(with: product)
        } else if let photobook = ProductManager.shared.products?.first {
            setup(with: photobook)
        }
    }
    
    private func setup(with product: PhotobookProduct) {
        setupTitleView()
        ProductManager.shared.setProduct(product, with: product.photobookTemplate)
        
        if emptyScreenViewController.parent != nil {
            collectionView.reloadData()
            emptyScreenViewController.hide(animated: true)
        }
    }
    
    private func setup(with photobook: PhotobookTemplate) {
        guard let assets = assets else {
            // Should never really reach here
            emptyScreenViewController.show(message: NSLocalizedString("Photobook/NoPhotosSelected", value: "No photos selected", comment: "No photos selected error message"))
            return
        }
        
        guard let _ = ProductManager.shared.setCurrentProduct(with: photobook, assets: assets) else { return }
        changedPhotobook()
        
        setup(with: product)
    }
    
    private func loadProducts() {
        emptyScreenViewController.show(message: NSLocalizedString("Photobook/Loading", value: "Loading products", comment: "Loading products screen message"), activity: true)
        ProductManager.shared.initialise(completion: { [weak welf = self] (errorMessage: ErrorMessage?) in
            guard let stelf = welf, let _ = ProductManager.shared.products?.first, errorMessage == nil else {
                let actionableErrorMessage = ActionableErrorMessage.withErrorMessage(errorMessage ?? ErrorMessage(.generic)) { welf?.loadProducts() }
                welf?.emptyScreenViewController.show(actionableErrorMessage)
                return
            }
            
            stelf.setupProduct()
        })
    }
    
    private func setupTitleView() {
        titleButton.setTitle(product.template.name, for: .normal)

        if let numberOfProducts = ProductManager.shared.products?.count, numberOfProducts == 1 {
            titleButton.setImage(nil, for: .normal)
        }
        
        titleButton.sizeToFit()
        navigationItem.titleView = titleButton
    }
    
    @objc private func didTapOnTitle() {
        guard let photobooks = ProductManager.shared.products, photobooks.count > 1 else { return }
        
        closeCurrentCell()
        
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("Photobook/ChangeSizeTitle", value: "Changing the size keeps your layout intact", comment: "Information when the user wants to change the photo book's size"), preferredStyle: .actionSheet)
        for photobook in photobooks {
            alertController.addAction(UIAlertAction(title: photobook.name, style: .default, handler: { [weak welf = self] (_) in
                guard let stelf = welf, stelf.product.photobookTemplate.id != photobook.id else { return }
                
                _ = ProductManager.shared.setCurrentProduct(with: photobook)
                stelf.changedPhotobook()
                
                stelf.setupTitleView()
                stelf.collectionView.reloadData()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
                
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func tappedCancel(_ sender: UIBarButtonItem) {
        cancelPhotobook()
    }

    private func switchRearrangeMode(_ status: ActiveState) {
        isRearranging = (status == .on)
        
        for cell in collectionView.visibleCells {
            (cell as? PhotobookCollectionViewCell)?.updateVoiceOver(isRearranging: isRearranging)
            (cell as? PhotobookCoverCollectionViewCell)?.updateVoiceOver(isRearranging: isRearranging)
        }
        
        UIView.animate(withDuration: Constants.rearrangeAnimationDuration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            for cell in self.collectionView.visibleCells {
                guard var photobookCell = cell as? InteractivePagesCell else { continue }
                photobookCell.isFaded = self.isRearranging && self.shouldFadeWhenRearranging(cell)
                photobookCell.isPageInteractionEnabled = !self.isRearranging
            }
            
            self.collectionView.transform = self.isRearranging ? CGAffineTransform(translationX: 0.0, y: -self.collectionView.frame.height * (1.0 - Constants.rearrangeScale) / 2.0).scaledBy(x: Constants.rearrangeScale, y: Constants.rearrangeScale) : .identity
            
            if self.isRearranging {
                self.ctaButtonContainerBottomConstraint.constant = -self.ctaButtonContainerHeightConstraint.constant
                self.view.layoutIfNeeded()
            }
        }, completion: nil)
    }
    
    private func shouldFadeWhenRearranging(_ cell: UICollectionViewCell) -> Bool {
        guard let indexPath = collectionView.indexPath(for: cell) else { return false }
        // Cover, first & last spreads return true, false for all other spreads
        return indexPath.row == 0 || indexPath.row == collectionView.numberOfItems(inSection: 1) - 1
    }
    
    @IBAction private func didTapCheckout(_ sender: Any) {
        guard draggingView == nil else { return }
        
        closeCurrentCell()
        
        let goToCheckout = {
            let orderSummaryViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "OrderSummaryViewController") as! OrderSummaryViewController
            orderSummaryViewController.completionClosure = self.completionClosure
            self.navigationController?.pushViewController(orderSummaryViewController, animated: true)
        }
        
        var emptyPageList = ""
        var truncatedPageList = ""
        var message = ""
        
        // Check for empty layouts
        if var emptyIndices = product.emptyLayoutIndices {
            if emptyIndices.first == 0 {
                message += NSLocalizedString("Photobook/MissingAssetsCover", value: "The cover is blank.", comment: "Alert message informing the user that the cover is blank")
                emptyIndices.removeFirst()
                if !emptyIndices.isEmpty { message += " " }
            }

            for index in emptyIndices {
                if !emptyPageList.isEmpty { emptyPageList += ", " }
                emptyPageList += String(index)
            }
            
            if !emptyPageList.isEmpty {
                if emptyIndices.count == 1 {
                    message += String(format: NSLocalizedString("Photobook/MissingAssetsMessageOnePage", value: "Page %@ is blank.", comment: "Alert message informing the user that they have one blank page"), emptyPageList)
                } else {
                    message += String(format: NSLocalizedString("Photobook/MissingAssetsMessageMultiplePages", value: "Pages %@ are blank.", comment: "Alert message informing the user that they have multiple blank pages"), emptyPageList)
                }
            }
        }

        // Check for truncated text
        if var truncatedIndices = product.truncatedTextLayoutIndices {
            if message.count > 0 { message += "\n" }
            
            if truncatedIndices.first == 0 {
                message += NSLocalizedString("Photobook/TruncatedTextCover", value: "The cover text will be truncated.", comment: "Alert message informing the user that the text on the cover will be truncated")
                truncatedIndices.removeFirst()
                if !truncatedIndices.isEmpty { message += " " }
            }
        
            for index in truncatedIndices {
                if !truncatedPageList.isEmpty { truncatedPageList += ", " }
                truncatedPageList += String(index)
            }
            
            if !truncatedPageList.isEmpty {
                if truncatedIndices.count == 1 {
                    message += String(format: NSLocalizedString("Photobook/TruncatedTextOnePage", value: "The text on page %@ will be truncated.", comment: "Alert message informing the user that the text one page will be truncated"), truncatedPageList)
                } else {
                    message += String(format: NSLocalizedString("Photobook/TruncatedTextMultiplePages", value: "The text on pages %@ will be truncated.", comment: "Alert message informing the user that the text on multiple pages will be truncated"), truncatedPageList)
                }
            }
        }
        
        guard message.isEmpty else {
            let alertController = UIAlertController(title: NSLocalizedString("Photobook/MissingAssetsTitle", value: "Continue to checkout?", comment: "Alert title informing the user that they have blank pages"), message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .default, handler: nil))
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default) { _ in
                goToCheckout()
            })
            present(alertController, animated: true, completion: nil)
            
            return
        }
        
        goToCheckout()
        
    }
        
    @IBAction private func didTapBack() {
        cancelPhotobook()
    }
    
    private func cancelPhotobook() {
        let alertController = UIAlertController(title: NSLocalizedString("Photobook/BackAlertTitle", value: "Are you sure?", comment: "Title for alert asking the user to go back"), message: NSLocalizedString("Photobook/BackAlertMessage", value: "This will discard any changes made to your photo book", comment: "Message for alert asking the user to go back"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Alert/Yes", value: "Yes", comment: "Affirmative button title for alert asking the user confirmation for an action"), style: .destructive, handler: { _ in
            
            self.closeCurrentCell()
            
            // Clear photobook
            ProductManager.shared.reset()
            
            Analytics.shared.trackAction(.wentBackFromPhotobookPreview)
            
            let controllerToDismiss: UIViewController = self.isPresentedModally() ? self.navigationController! : self
            guard self.completionClosure != nil else {
                self.autoDismiss(true)
                return
            }
            self.completionClosure?(controllerToDismiss, false)
        }))
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    private func updateNavBar() {
        guard let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar else { return }
        
        let navigationBarMaxY = (navigationController?.navigationBar.frame.maxY ?? 0)
        
        var draggingViewUnderNavBar = false
        if let draggingView = draggingView {
            draggingViewUnderNavBar = draggingView.frame.origin.y < navigationBarMaxY
        }
        
        let showBlur = collectionView.contentOffset.y > -navigationBarMaxY || draggingViewUnderNavBar
        photobookNavigationBarType = showBlur ? .white : .clear
        navigationBar.setBarType(photobookNavigationBarType)
    }
    
    private func stopTimer() {
        scrollingTimer?.invalidate()
        scrollingTimer = nil
    }
    
    @objc private func albumsWereUpdated(_ notification: Notification) {
        guard let albumsChanges = notification.object as? [AlbumChange] else { return }
        
        var removedAssets = [Asset]()
        for albumChange in albumsChanges {
            if let assetsRemoved = PhotobookAsset.assets(from: albumChange.assetsRemoved) {
                removedAssets.append(contentsOf: assetsRemoved)
            }
        }
        
        for removedAsset in removedAssets {
            if let removedIndex = product.productLayouts.firstIndex(where: { $0.asset?.identifier == removedAsset.identifier }) {
                product.productLayouts[removedIndex].asset = nil
                
                // Check if the cover needs refreshing
                if removedIndex == 0 && !collectionView.indexPathsForVisibleItems.contains(IndexPath(item: 0, section: 0)) {
                    continue
                } else if (removedIndex == 0), let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? PhotobookCoverCollectionViewCell {
                    cell.loadCoverAndSpine()
                    continue
                }
                
                let spreadIndex = product.spreadIndex(for: removedIndex)
                if let visibleIndexPathToLoad = collectionView.indexPathsForVisibleItems.filter({ $0.item == spreadIndex && $0.section == 1 }).first,
                    let cell = collectionView.cellForItem(at: visibleIndexPathToLoad) as? PhotobookCollectionViewCell
                {
                    if cell.leftIndex == removedIndex || cell.rightIndex == removedIndex {
                        cell.loadPages()
                        cell.updateVoiceOver(isRearranging: isRearranging)
                    }
                }
            }
        }
    }
    
    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Drag and Drop
    
    private func deleteProposalCell(enableFeedback: Bool) {
        guard let indexPath = proposedDropIndexPath else { return }
        proposedDropIndexPath = nil
        collectionView.deleteItems(at: [indexPath])
        
        if enableFeedback {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    private func insertProposalCell(_ indexPath: IndexPath) {
        proposedDropIndexPath = indexPath
        collectionView.insertItems(at: [indexPath])
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func dropView() {
        guard let sourceIndexPath = interactingItemIndexPath, let draggingView = draggingView else { return }
        
        let sourceCell = (collectionView.cellForItem(at: sourceIndexPath) as? PhotobookCollectionViewCell)
        
        let destinationIndexPath = proposedDropIndexPath ?? sourceIndexPath
        let movingDown = sourceIndexPath.item < destinationIndexPath.item
                
        let destinationY: CGFloat
        if let destinationCell = collectionView.cellForItem(at: IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 0), section: destinationIndexPath.section)) {
            destinationY = collectionView.convert(destinationCell.frame, to: view).origin.y
        } else if draggingView.frame.origin.y + draggingView.frame.height > view.frame.height / 2.0 {
            destinationY = -draggingView.frame.height
        } else {
            destinationY = view.frame.height + draggingView.frame.height
        }
        
        let destinationPoint = CGPoint(x: Constants.cellSideMargin, y: destinationY * self.reverseRearrangeScale)
        if destinationPoint == draggingView.frame.origin {
            // If the dragging view is in place, slightly offset its position to avoid an abrupt animation
            draggingView.frame.origin = CGPoint(x: draggingView.frame.origin.x, y: draggingView.frame.origin.y + 1.0)
            view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: Constants.dropAnimationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
            draggingView.frame.origin = destinationPoint
            draggingView.layer.shadowRadius = 0
            draggingView.layer.shadowOpacity = 0
        }, completion: { _ in
            // Unhide the book if we're returning to the original position
            sourceCell?.isVisible = true
            sourceCell?.shouldRevealActions = true
            
            draggingView.removeFromSuperview()
            self.draggingView = nil
            self.interactingItemIndexPath = nil
            
            if let insertingIndexPath = self.insertingIndexPath, let cell = self.collectionView.cellForItem(at: insertingIndexPath) as? PhotobookCollectionViewCell {
                cell.isVisible = true
                cell.shouldRevealActions = true
                cell.backgroundColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1.0)
                self.insertingIndexPath = nil
            }
            
            UIView.animate(withDuration: Constants.rearrangeAnimationDuration, delay: 0.0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.ctaButtonContainerBottomConstraint.constant = 0.0
                self.view.layoutIfNeeded()
            })
        })
        
        if destinationIndexPath != sourceIndexPath,
            let sourceProductLayoutIndex = product.productLayoutIndex(for: sourceIndexPath.item) {
            
            // Because we show a placeholder graphic where the drop proposal is, we get the destination index from the previous page
            let previousIndexPath = IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 1), section: destinationIndexPath.section)
            let previousCell = (collectionView.cellForItem(at: previousIndexPath) as? PhotobookCollectionViewCell)
            
            guard let destinationProductLayoutIndex = previousCell?.leftIndex ?? previousCell?.rightIndex else { return }
            
            product.moveLayout(from: sourceProductLayoutIndex, to: destinationProductLayoutIndex)
            changedPhotobook()
            
            interactingItemIndexPath = nil
            
            let insertingIndexPath = IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 0), section: destinationIndexPath.section)
            self.insertingIndexPath = insertingIndexPath
            
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: [insertingIndexPath])
                deleteProposalCell(enableFeedback: false)
                collectionView.deleteItems(at: [IndexPath(item: sourceIndexPath.item + (movingDown ? 0 : 1), section: sourceIndexPath.section)])
            }, completion: { _ in
                self.updateVisibleCells()
            })
            
            Analytics.shared.trackAction(.rearrangedPages)
        }
    }
    
    private func liftView(_ photobookFrameView: PhotobookFrameView) {
        guard let productLayoutIndex = photobookFrameView.leftPageView.pageIndex,
            let spreadIndex = product.spreadIndex(for: productLayoutIndex),
            spreadIndex != collectionView.numberOfItems(inSection: 1) - 1
            else { return }
        
        interactingItemIndexPath = IndexPath(item: spreadIndex, section: 1)
        guard let snapshot = photobookFrameView.snapshotView(afterScreenUpdates: true),
            let bookSuperview = photobookFrameView.superview else { return }
        
        draggingView = snapshot
        view.addSubview(snapshot)
        snapshot.frame = bookSuperview.convert(photobookFrameView.frame, to: view)
        
        UIView.animate(withDuration: Constants.dragLiftAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
            snapshot.layer.shadowRadius = 10
            snapshot.layer.shadowOpacity = 0.5
        }, completion: { _ in
            (self.collectionView.cellForItem(at: IndexPath(item: spreadIndex, section: 1)) as? PhotobookCollectionViewCell)?.isVisible = false
        })
    }
    
    private func updateVisibleCells() {
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                let productLayoutIndex = product.productLayoutIndex(for: indexPath.item),
                let cell = cell as? PhotobookCollectionViewCell
                else { continue }

            cell.leftIndex = productLayoutIndex
            if product.productLayouts[productLayoutIndex].layout.isDoubleLayout {
                cell.rightIndex = productLayoutIndex
            } else {
                let rightIndex = productLayoutIndex < product.productLayouts.count - 1 ? productLayoutIndex + 1 : nil
                cell.rightIndex = rightIndex
            }
            cell.indexPath = indexPath
            cell.loadPages()
            cell.updateVoiceOver(isRearranging: isRearranging)
        }
    }
    
    private func editPage(_ page: PhotobookPageView, at index: Int, frame: CGRect, containerView: UIView) {
        closeCurrentCell() {
            self.interactingItemIndexPath = nil
        }
        
        let modalNavigationController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PageSetupNavigationController") as! UINavigationController
        if #available(iOS 11.0, *) {
            modalNavigationController.navigationBar.prefersLargeTitles = false
        }

        let barType = (navigationController?.navigationBar as? PhotobookNavigationBar)?.barType
        
        let pageSetupViewController = modalNavigationController.viewControllers.first as! PageSetupViewController
        pageSetupViewController.pageIndex = index
        pageSetupViewController.assetsDelegate = self
        pageSetupViewController.photobookDelegate = photobookDelegate
        
        if barType != nil {
            pageSetupViewController.photobookNavigationBarType = barType!
        }
        pageSetupViewController.delegate = self
        
        if barType == .clear {
            UIView.animate(withDuration: 0.1) {
                self.navigationController!.navigationBar.alpha = 0.0
            }
        }
        present(modalNavigationController, animated: false) {
            let containerRect = pageSetupViewController.view.convert(frame, from: containerView)
            pageSetupViewController.animateFromPhotobook(frame: containerRect) {
                self.navigationController!.navigationBar.alpha = 0.0
            }
        }
    }
    
    private func showNotAllowedToAddMorePagesAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Photobook/TooManyPagesAlertTitle", value: "Too many pages", comment: "Alert title informing the user that they have reached the maximum number of pages"), message: NSLocalizedString("Photobook/TooManyPagesAlertMessage", value: "You cannot add any more pages to your photo book", comment: "Alert message informing the user that they have reached the maximum number of pages"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // Cell actions
    private func duplicatePages(at indexPath: IndexPath) {
        guard product.isAddingPagesAllowed else {
            showNotAllowedToAddMorePagesAlert()
            return
        }
        
        guard let cell = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell),
            let leftIndex = cell.leftIndex
            else { return }
        
        let leftProductLayout = product.productLayouts[leftIndex]
        var productLayouts = [leftProductLayout.shallowCopy()]
        
        if !leftProductLayout.layout.isDoubleLayout, let rightIndex = cell.rightIndex {
            let rightProductLayout = product.productLayouts[rightIndex]
            productLayouts.append(rightProductLayout.shallowCopy())
        } else {
            return
        }
        
        guard var index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex else { return }
        index = product.productLayouts[index].layout.isDoubleLayout ? index + 1 : index + 2
        let targetIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
        
        // Insert new page below the tapped one
        product.addPages(at: index, pages: productLayouts)
        changedPhotobook()
        
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [targetIndexPath])
        }, completion: { _ in
            self.updateVisibleCells()
        })
        
        Analytics.shared.trackAction(.pastedPages)
    }
    
    func addPages(after indexPath: IndexPath) {
        guard product.isAddingPagesAllowed else {
            showNotAllowedToAddMorePagesAlert()
            return
        }
        
        var index: Int!
        if indexPath.item == 0 {
            index = 2 // Adding a pages after the first spread
        } else {
            index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex
            index = product.productLayouts[index].layout.isDoubleLayout ? index + 1 : index + 2
        }
        let targetIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
        
        // Insert new page below the selected indexPath
        product.addDoubleSpread(at: index)
        changedPhotobook()
        
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [targetIndexPath])
        }, completion: { _ in
            self.updateVisibleCells()
        })
        
        Analytics.shared.trackAction(.addedPages)
    }

    private func deletePages(at indexPath: IndexPath) {
        guard let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex
            else { return }
        
        guard product.isRemovingPagesAllowed else {
            let alertController = UIAlertController(title: NSLocalizedString("Photobook/CannotDeleteAlertTitle", value: "Cannot Delete Page", comment: "Alert title letting the user know they can't delete a page from the book"), message: NSLocalizedString("Photobook/CannotDeleteAlertMessage", value: "Your photo book currently contains the minimum number of pages allowed", comment: "Alert message letting the user know they can't delete a page from the book"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let productLayout = product.productLayouts[index]
        
        product.deletePages(for: productLayout)
        changedPhotobook()
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCells()
        })
        
        Analytics.shared.trackAction(.deletedPages)
    }

    private func changedPhotobook() {
        ProductManager.shared.changedCurrentProduct(with: assets)
    }
    
    private func closeCurrentCell(completion:(()->())? = nil) {
        guard interactingItemIndexPath != nil,
            let cell = collectionView.cellForItem(at: interactingItemIndexPath!) as? PhotobookCollectionViewCell,
            cell.isOpen else {
            completion?()
            return
        }
        cell.animateCellClosed() {
            cell.isPageInteractionEnabled = true
            cell.shouldRevealActions = true
            completion?()
        }
    }
}

extension PhotobookViewController: UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard product != nil else { return 0 }
        
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 1:
            guard let lastSpreadIndex = product.spreadIndex(for: product.productLayouts.count - 1) else { return 0 }
            return lastSpreadIndex + 1 + (proposedDropIndexPath != nil ? 1 : 0)
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotobookCoverCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotobookCoverCollectionViewCell
            cell.product = product
            cell.width = (view.bounds.size.width - Constants.cellSideMargin * 2.0) / 2.0
            cell.delegate = self
            cell.isPageInteractionEnabled = !isRearranging
            cell.isFaded = isRearranging
            
            return cell
        default:
            if let proposedDropIndexPath = proposedDropIndexPath, indexPath.item == proposedDropIndexPath.item {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "ProposalCollectionViewCell", for: indexPath)
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotobookCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotobookCollectionViewCell
            cell.product = product
            cell.isVisible = indexPath != interactingItemIndexPath && indexPath != insertingIndexPath
            cell.width = view.bounds.size.width - Constants.cellSideMargin * 2.0
            cell.clipsToBounds = false
            cell.indexPath = indexPath
            cell.actionsDelegate = self
            cell.delegate = self
            
            // First and last pages of the book are courtesy pages, no photos on them
            var leftIndex: Int? = nil
            var rightIndex: Int? = nil
            switch indexPath.item {
            case 0:
                rightIndex = 1
                cell.shouldRevealActions = !isRearranging
                cell.isFaded = isRearranging
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                leftIndex = product.productLayouts.count - 1
                cell.shouldRevealActions = false
                cell.isFaded = isRearranging
            default:
                let indexPathItem = indexPath.item - ((proposedDropIndexPath?.item ?? Int.max) < indexPath.item ? 1 : 0)
                guard let index = product.productLayoutIndex(for: indexPathItem) else { return cell }
                leftIndex = index
                let isDoubleLayout = product.productLayouts[leftIndex!].layout.isDoubleLayout
                
                if isDoubleLayout {
                    rightIndex = leftIndex
                } else if leftIndex! + 1 < product.productLayouts.count {
                    rightIndex = index + 1
                }
                cell.setupGestures()
                cell.isPageInteractionEnabled = !isRearranging
                cell.shouldRevealActions = !isRearranging
                cell.isFaded = false
            }
            
            cell.leftIndex = leftIndex
            cell.rightIndex = rightIndex
            
            return cell
        }
    }    
}

extension PhotobookViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavBar()
        if interactingItemIndexPath != nil,
            let cell = collectionView.cellForItem(at: interactingItemIndexPath!) as? PhotobookCollectionViewCell,
            cell.isOpen {
                cell.animateCellClosed()
                interactingItemIndexPath = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotobookCollectionViewCell {
            cell.loadPages()
            cell.setUpActions()
            cell.updateVoiceOver(isRearranging: isRearranging)
        } else if let cell = cell as? PhotobookCoverCollectionViewCell {
            cell.loadCoverAndSpine()
            cell.updateVoiceOver(isRearranging: isRearranging)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath == proposedDropIndexPath {
            return CGSize(width: collectionView.bounds.width, height: Constants.proposalCellHeight)
        }

        let pageWidth = (view.bounds.width - Constants.cellSideMargin * 2.0 - PhotobookConstants.horizontalPageToCoverMargin * 2.0) / 2.0
        let pageHeight = pageWidth / product.photobookTemplate.pageAspectRatio

        // PhotoboookCollectionViewCell works when the collectionView uses dynamic heights by setting up the aspect ratio of its pages.
        // This however, causes problems with the drag & drop functionality and that is why the cell height is calculated by using the measurements set on the storyboard.
        return CGSize(width: view.bounds.width - Constants.cellSideMargin * 2.0, height: pageHeight + PhotobookConstants.verticalPageToCoverMargin * 2.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Reduces the space between cover and first page to match the one between pages
        if section == 0 {
            return UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: -18.0, right: 0.0)
        }
        return .zero
    }
}

extension PhotobookViewController: PhotobookCoverCollectionViewCellDelegate {
    
    func didTapOnSpine(with rect: CGRect, in containerView: UIView) {
        closeCurrentCell() {
            self.interactingItemIndexPath = nil
        }
        
        let initialRect = containerView.convert(rect, to: view)
        
        let spineTextEditingNavigationController = photobookMainStoryboard.instantiateViewController(withIdentifier: "SpineTextEditingNavigationController") as! UINavigationController
        let spineTextEditingViewController = spineTextEditingNavigationController.viewControllers.first! as! SpineTextEditingViewController
        spineTextEditingViewController.initialRect = initialRect
        spineTextEditingViewController.delegate = self
        
        navigationController?.present(spineTextEditingNavigationController, animated: false, completion: nil)
    }
    
    func didTapOnCover(_ cover: PhotobookPageView, with frame: CGRect, in containerView: UIView) {
        editPage(cover, at: 0, frame: frame, containerView: containerView)
    }
}

extension PhotobookViewController: PageSetupDelegate {
    // MARK: PageSetupDelegate
    
    func didFinishEditingPage(_ index: Int?, pageType: PageType?, productLayout: ProductLayout?, color: ProductColor?, editor: PageSetupViewController) {
        if let index = index {
            if let productLayout = productLayout {
                trackAnalyticsActionsForEditingFinished(index: index, productLayout: productLayout)
                product.replaceLayout(at: index, with: productLayout, pageType: pageType)
            }
            if let color = color {
                if index == 0 { // Cover
                    product.coverColor = color
                } else {
                    product.pageColor = color
                }
            }
            collectionView.reloadData()
        }
        changedPhotobook()
        
        let barType = (navigationController?.navigationBar as? PhotobookNavigationBar)?.barType

        UIView.animate(withDuration: barType == .white ? 0.3 : 0.1, delay: barType == .white ? 0.0 : 0.2, options: [], animations: {
            self.navigationController!.navigationBar.alpha = 1.0
        }, completion: nil)

        editor.animateBackToPhotobook {
            self.dismiss(animated: false)
        }
    }
    
    func trackAnalyticsActionsForEditingFinished(index: Int, productLayout: ProductLayout) {
        let previousLayout = product.productLayouts[index]
        
        if previousLayout.productLayoutText?.text != productLayout.productLayoutText?.text {
            Analytics.shared.trackAction(.addedTextToPage)
        }
        if !previousLayout.layout.isDoubleLayout && productLayout.layout.isDoubleLayout {
            Analytics.shared.trackAction(.usingDoublePageLayout)
        }
        if index == 0 && previousLayout.layout.id != productLayout.layout.id {
            Analytics.shared.trackAction(.coverLayoutChanged)
        }
    }
}

extension PhotobookViewController: PhotobookCollectionViewCellDelegate {

    func didTapOnPage(_ page: PhotobookPageView, at index: Int, frame: CGRect, in containerView: UIView) {
        editPage(page, at: index, frame: frame, containerView: containerView)
    }

    func didLongPress(_ sender: UILongPressGestureRecognizer, on cell: PhotobookCollectionViewCell) {                
        if sender.state == .began {
            guard let photobookFrameView = sender.view as? PhotobookFrameView else {
                fatalError("Long press failed to recognise the target view")
            }
            
            // Disallow dragging first and last pages
            guard let indexPath = collectionView.indexPath(for: cell),
                  indexPath.row > 0 && indexPath.row < collectionView.numberOfItems(inSection: 1) - 1
                else { return }
            
            closeCurrentCell() {
                cell.shouldRevealActions = false
                self.liftView(photobookFrameView)
                self.switchRearrangeMode(.on)
            }
        } else if sender.state == .ended {
            self.dropView()
            self.switchRearrangeMode(.off)
            self.stopTimer()
        }
    }
    
    func didPan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            isDragging = true
        } else if sender.state == .ended {
            isDragging = false
        }
        guard let draggingView = draggingView, sender.state == .changed else { return }
        
        currentlyPanningGesture = sender
        
        let translation = sender.translation(in: view)
        draggingView.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
        autoScrollIfNeeded()
        updateNavBar()
        
        let dragPointOnCollectionView = CGPoint(x: collectionView.frame.size.width / 2.0, y: sender.location(in: collectionView).y)
        guard let indexPathForDragPoint = collectionView.indexPathForItem(at: dragPointOnCollectionView),
            let cell = collectionView.cellForItem(at: indexPathForDragPoint),
            let interactingItemIndexPath = interactingItemIndexPath
            else { return }
        let dragPointOnCell = collectionView.convert(dragPointOnCollectionView, to: cell)
        
        let proposedIndexPath: IndexPath
        if dragPointOnCell.y > cell.frame.size.height / 2.0 {
            proposedIndexPath = IndexPath(item: indexPathForDragPoint.item + 1, section: indexPathForDragPoint.section)
        } else {
            proposedIndexPath = indexPathForDragPoint
        }
        
        // If the proposed path hasn't changed, there's no need to proceed
        guard proposedIndexPath != proposedDropIndexPath,
            proposedDropIndexPath == nil || proposedIndexPath.item != proposedDropIndexPath!.item + 1
            else { return }
        
        // Clear proposed drop index path if the proposal is:
        guard proposedIndexPath != interactingItemIndexPath, // back to the where we picked it up
            proposedIndexPath.item != 0, // at the first page or cover
            proposedIndexPath.section != 0, // at the cover
            proposedIndexPath.item != interactingItemIndexPath.item + 1, // just below of where we picked up
            proposedIndexPath.item < collectionView.numberOfItems(inSection: proposedIndexPath.section) // out of bounds
            else {
                deleteProposalCell(enableFeedback: true)
                return
        }
        
        // Delete any existing proposal and insert the new one
        collectionView.performBatchUpdates({
            self.deleteProposalCell(enableFeedback: false)
            self.insertProposalCell(proposedIndexPath)
        })
    }
    
    func autoScrollIfNeeded() {
        guard let draggingView = draggingView else { return }
        
        // Auto-scroll the collectionView if you drag to the top or bottom
        if draggingView.frame.origin.y + draggingView.frame.size.height / 2.0 > view.frame.size.height * Constants.autoScrollBottomScreenThreshold {
            guard scrollingTimer == nil else { return }
            
            timerBlock = { [weak welf = self] in
                guard welf != nil else { return }
                if welf!.collectionView.contentOffset.y + welf!.collectionView.frame.size.height + (welf!.navigationController?.navigationBar.frame.maxY ?? 0) - Constants.proposalCellHeight < welf!.collectionView.contentSize.height {
                    welf!.collectionView.contentOffset = CGPoint(x: welf!.collectionView.contentOffset.x, y: welf!.collectionView.contentOffset.y + Constants.autoScrollOffset)
                    if let gesture = welf!.currentlyPanningGesture{
                        welf!.didPan(gesture)
                    }
                }
            }
            scrollingTimer = Timer(timeInterval: screenRefreshRate, target: self, selector: #selector(invokeTimerBlock), userInfo: [], repeats: true)
        }
        else if (draggingView.frame.origin.y + draggingView.frame.size.height / 2.0 < view.frame.size.height * Constants.autoScrollTopScreenThreshold) {
            guard scrollingTimer == nil else { return }
            
            timerBlock = { [weak welf = self] in
                guard welf != nil else { return }
                if welf!.collectionView.contentOffset.y > -(welf!.navigationController?.navigationBar.frame.maxY ?? 0) {
                    welf!.collectionView.contentOffset = CGPoint(x: welf!.collectionView.contentOffset.x, y: welf!.collectionView.contentOffset.y - Constants.autoScrollOffset)
                }
            }
            scrollingTimer = Timer(timeInterval: screenRefreshRate, target: self, selector: #selector(invokeTimerBlock), userInfo: nil, repeats: true)
        }
        else {
            stopTimer()
        }
        
        if let timer = scrollingTimer {
            RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        }
    }
    
    @objc private func invokeTimerBlock() {
        timerBlock?()
    }
}

extension PhotobookViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !isDragging
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer as? UILongPressGestureRecognizer == nil else { return false }
        return otherGestureRecognizer.view === gestureRecognizer.view || draggingView == nil
    }
}

extension PhotobookViewController: SpineTextEditingDelegate {
    
    func didCancelSpineTextEditing(_ spineTextEditingViewController: SpineTextEditingViewController) {
        spineTextEditingViewController.animateOff {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func didSaveSpineTextEditing(_ spineTextEditingViewController: SpineTextEditingViewController, spineText: String?, fontType: FontType) {
        product.spineText = spineText
        product.spineFontType = fontType
        changedPhotobook()
        
        collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
        
        spineTextEditingViewController.animateOff {
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension PhotobookViewController: ActionsCollectionViewCellDelegate {
    
    func actionButtonConfigurationForButton(at index: Int, indexPath: IndexPath) -> ActionButtonViewConfiguration? {
        guard indexPath.section == 1 else { return nil }
        var title: String!
        var image: UIImage!
        
        switch index {
        case 0 where indexPath.item > 0:
            title = NSLocalizedString("Photobook/Cell/DeleteButton", value: "Delete", comment: "Text for the delete button in a spread")
            image = UIImage(namedInPhotobookBundle: "delete")
        case 1 where indexPath.item > 0, 0 where indexPath.item == 0:
            title = NSLocalizedString("Photobook/Cell/AddButton", value: "Add", comment: "Text for the add button in a spread")
            image = UIImage(namedInPhotobookBundle: "add")
        case 2 where indexPath.item > 0:
            title = NSLocalizedString("Photobook/Cell/DuplicateButton", value: "Duplicate", comment: "Text for the duplicate button in a spread")
            image = UIImage(namedInPhotobookBundle: "duplicate")
        default:
            return nil
        }
        return ActionButtonViewConfiguration(title: title, image: image)
    }
    
    func didTapActionButton(at index: Int, for indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        
        closeCurrentCell() {
            self.interactingItemIndexPath = nil
            
            switch index {
            case 0 where indexPath.item > 0:
                self.deletePages(at: indexPath)
            case 1 where indexPath.item > 0, 0 where indexPath.item == 0:
                self.addPages(after: indexPath)
            case 2 where indexPath.item > 0:
                self.duplicatePages(at: indexPath)
            default:
                return
            }
        }
    }
    
    func didCloseCell(at indexPath: IndexPath) {
        guard interactingItemIndexPath != nil, let cell = collectionView.cellForItem(at: interactingItemIndexPath!) as? PhotobookCollectionViewCell else { return }
        cell.isPageInteractionEnabled = true
        cell.shouldRevealActions = true
        interactingItemIndexPath = nil
    }
    
    func didOpenCell(at indexPath: IndexPath) {
        if interactingItemIndexPath != nil && interactingItemIndexPath != indexPath {
            closeCurrentCell() {
                self.interactingItemIndexPath = indexPath
            }
        } else {
            interactingItemIndexPath = indexPath
        }
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell else { return }
        cell.isPageInteractionEnabled = false
    }
}
