//
//  PhotobookViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookViewController: UIViewController, PhotobookNavigationBarDelegate {
    
    var photobookNavigationBarType: PhotobookNavigationBarType = .clear
    
    /// Array of Assets to populate the pages of the photobook.
    var assets: [Asset]!
    
    /// Album to use in order to have access to additional Assets when editing a page. 'album', 'albumManager' & 'assetPickerViewController' are exclusive.
    var album: Album?
    
    /// Manager for multiple albums to use in order to have access to additional Assets when editing a page. 'album', 'albumManager' & 'assetPickerViewController' are exclusive.
    var albumManager: AlbumManager?
    
    /// View controller allowing the user to pick additional assets. 'album', 'albumManager' & 'assetPickerViewController' are exclusive.
    var assetPickerViewController: PhotobookAssetPicker?
    
    /// Delegate to dismiss the PhotobookViewController
    var dismissClosure: (() -> Void)?
    
    var showCancelButton: Bool = false
    
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
        static let doneBlueColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        static let rearrangeGreyColor = UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0)
    }
    private var reverseRearrangeScale: CGFloat {
        return 1 + (1 - Constants.rearrangeScale) / Constants.rearrangeScale
    }

    @IBOutlet private weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var ctaContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var ctaButton: UIButton!
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var ctaButtonContainer: UIView!
    @IBOutlet private var backButton: UIButton?
    private lazy var cancelBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tappedCancel(_:)))
    }()
    
    private var titleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(namedInPhotobookBundle:"chevron-down"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: Constants.titleArrowOffset)
        button.addTarget(self, action: #selector(didTapOnTitle), for: .touchUpInside)
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
    
    // Scrolling at 60Hz when we are dragging looks good enough and avoids having to normalize the scroll offset
    private lazy var screenRefreshRate: Double = 1.0 / 60.0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.photobook)
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        (tabBarController?.tabBar as? PhotobookTabBar)?.isBackgroundHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        adjustInsets()
    }
    
    private func adjustInsets() {
        let insets: UIEdgeInsets
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
        } else {
            insets = .zero
        }
        
        let bottomInset = isRearranging ? ctaButtonContainer.frame.size.height * reverseRearrangeScale - insets.bottom : ctaButtonContainer.frame.size.height - insets.bottom - collectionViewBottomConstraint.constant
        
        let normalTopInset: CGFloat
        let multiplier: CGFloat
        if #available(iOS 11, *) {
            normalTopInset = 0
            multiplier = 1 - Constants.rearrangeScale
        } else {
            normalTopInset = navigationController?.navigationBar.frame.maxY ?? 0
            multiplier = 1 + Constants.rearrangeScale
        }
        
        let rearrangingTopInset = (navigationController?.navigationBar.frame.maxY ?? 0) * multiplier
        
        collectionView.contentInset = UIEdgeInsets(top: isRearranging ? rearrangingTopInset : normalTopInset, left: collectionView.contentInset.left, bottom: bottomInset, right: collectionView.contentInset.right)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
    }
    
    private func setup() {
        collectionViewBottomConstraint.constant = -view.frame.height * (reverseRearrangeScale - 1)
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        } else {
            ctaContainerBottomConstraint.isActive = false
            ctaContainerBottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: ctaButton, attribute: .bottom, multiplier: 1, constant: ctaContainerBottomConstraint.constant)
            ctaContainerBottomConstraint.isActive = true
        }
        
        navigationItem.hidesBackButton = true
    
        if showCancelButton {
            navigationItem.leftBarButtonItems = [ cancelBarButtonItem ]
        } else {
            backButton?.setTitleColor(navigationController?.navigationBar.tintColor, for: .normal)
        }
        
        // Remove pasteboard so that we avoid edge-cases with stale or inconsistent data
        UIPasteboard.remove(withName: UIPasteboardName("ly.kite.photobook.rearrange"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(albumsWereUpdated(_:)), name: AssetsNotificationName.albumsWereUpdated, object: nil)
        
        if let photobook = ProductManager.shared.products?.first {
            setup(with: photobook)
        } else {
            loadProducts()
        }
    }
    
    private func setup(with photobook: PhotobookTemplate) {
        guard let assets = assets else {
            // Should never really reach here
            emptyScreenViewController.show(message: NSLocalizedString("Photobook/NoPhotosSelected", value: "No photos selected", comment: "No photos selected error message"))
            return
        }
        
        guard
            let coverLayouts = ProductManager.shared.coverLayouts(for: photobook),
            !coverLayouts.isEmpty,
            let layouts = ProductManager.shared.layouts(for: photobook),
            !layouts.isEmpty
            else {
                print("ProductManager: Missing layouts for selected photobook")
                return
        }
        
        ProductManager.shared.currentProduct = PhotobookProduct(template: photobook, assets: assets, coverLayouts: coverLayouts, layouts: layouts)
        
        setupTitleView()
        
        if emptyScreenViewController.parent != nil {
            collectionView.reloadData()
            emptyScreenViewController.hide(animated: true)
        }
    }
    
    private func loadProducts() {
        emptyScreenViewController.show(message: NSLocalizedString("Photobook/Loading", value: "Loading products", comment: "Loading products screen message"), activity: true)
        ProductManager.shared.initialise(completion: { [weak welf = self] (error: Error?) in
            guard let photobook = ProductManager.shared.products?.first, error == nil else {
                welf?.emptyScreenViewController.show(message: error?.localizedDescription ?? "Error", buttonTitle: CommonLocalizedStrings.retry, buttonAction: {
                    welf?.loadProducts()
                })
                return
            }
            
            welf?.setup(with: photobook)
        })
    }
    
    private func setupTitleView() {
        if !isRearranging {
            titleButton.setTitle(product.template.name, for: .normal)
            titleButton.sizeToFit()
            navigationItem.titleView = titleButton
            return
        }
        
        navigationItem.titleView = nil
        navigationItem.title = NSLocalizedString("Photobook/RearrangeTitle", value: "Rearranging Pages", comment: "Title of the photobook preview screen in rearrange mode")
    }
    
    @objc private func didTapOnTitle() {
        guard let photobooks = ProductManager.shared.products else { return }
        
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("Photobook/ChangeSizeTitle", value: "Changing the size keeps your layout intact", comment: "Information when the user wants to change the photo book's size"), preferredStyle: .actionSheet)
        for photobook in photobooks{
            alertController.addAction(UIAlertAction(title: photobook.name, style: .default, handler: { [weak welf = self] (_) in
                guard welf?.product.template.id != photobook.id else { return }
                
                guard
                    let coverLayouts = ProductManager.shared.coverLayouts(for: photobook),
                    !coverLayouts.isEmpty,
                    let layouts = ProductManager.shared.layouts(for: photobook),
                    !layouts.isEmpty
                    else {
                        print("ProductManager: Missing layouts for selected photobook")
                        return
                }
                
                welf?.product.setTemplate(photobook, coverLayouts: coverLayouts, layouts: layouts)
                
                welf?.setupTitleView()
                welf?.collectionView.reloadData()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.cancel, style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func tappedCancel(_ sender: UIBarButtonItem) {
        guard let dismissClosure = dismissClosure else {
            if presentingViewController != nil {
                presentingViewController!.dismiss(animated: true, completion: nil)
                return
            }
            navigationController?.popViewController(animated: true)
            return
        }
        dismissClosure()
    }

    @IBAction private func didTapRearrange(_ sender: UIBarButtonItem) {
        isRearranging = !isRearranging
        
        // Update drag interaction enabled status
        let interactiveCellClosure: ((Bool) -> Void) = { (isRearranging) in
            UIView.animate(withDuration: Constants.rearrangeAnimationDuration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                for cell in self.collectionView.visibleCells {
                    guard var photobookCell = cell as? InteractivePagesCell else { continue }
                    photobookCell.isFaded = isRearranging && self.shouldFadeWhenRearranging(cell)
                    photobookCell.isPageInteractionEnabled = !isRearranging
                }
                
                self.collectionView.transform = isRearranging ? CGAffineTransform(translationX: 0.0, y: -self.collectionView.frame.height * (1.0 - Constants.rearrangeScale) / 2.0).scaledBy(x: Constants.rearrangeScale, y: Constants.rearrangeScale) : .identity
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: nil)
        }

        interactiveCellClosure(isRearranging)
        if isRearranging {
            navigationItem.setLeftBarButtonItems(nil, animated: true)
            sender.title = NSLocalizedString("Photobook/DoneButtonTitle", value: "Done", comment: "Done button title")
            sender.tintColor = Constants.doneBlueColor
        } else {
            let barButtonItem = showCancelButton ? cancelBarButtonItem : UIBarButtonItem(customView: backButton!)
            navigationItem.setLeftBarButtonItems([barButtonItem], animated: true)
            sender.title = NSLocalizedString("Photobook/RearrangeButtonTitle", value: "Rearrange", comment: "Rearrange button title")
            sender.tintColor = Constants.rearrangeGreyColor
        }
        
        setupTitleView()
    }
    
    private func shouldFadeWhenRearranging(_ cell: UICollectionViewCell) -> Bool {
        guard let indexPath = collectionView.indexPath(for: cell) else { return false }
        // Cover, first & last spreads return true, false for all other spreads
        return indexPath.row == 0 || indexPath.row == collectionView.numberOfItems(inSection: 1) - 1
    }
    
    @IBAction private func didTapCheckout(_ sender: Any) {
        guard draggingView == nil else { return }
        
        let goToCheckout = {
            let orderSummaryViewController = photobookMainStoryboard.instantiateViewController(withIdentifier: "OrderSummaryViewController") as! OrderSummaryViewController
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
        let alertController = UIAlertController(title: NSLocalizedString("Photobook/BackAlertTitle", value: "Are you sure?", comment: "Title for alert asking the user to go back"), message: NSLocalizedString("Photobook/BackAlertMessage", value: "This will discard any changes made to your photobook", comment: "Message for alert asking the user to go back"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Alert/Yes", value: "Yes", comment: "Affirmative button title for alert asking the user confirmation for an action"), style: .destructive, handler: { _ in
            
            // Clear photobook
            ProductManager.shared.reset()
            
            self.navigationController?.popViewController(animated: true)
            
            Analytics.shared.trackAction(.wentBackFromPhotobookPreview)
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
            removedAssets.append(contentsOf: albumChange.assetsRemoved)
        }
        
        for removedAsset in removedAssets {
            if let removedIndex = product.productLayouts.index(where: { $0.asset?.identifier == removedAsset.identifier }) {
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
                    }
                }
            }
        }
    }
    
    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIMenuController actions
    
    @objc private func cutPages() {
        copyPages()
        deletePages()
    }
    
    @objc private func copyPages() {
        guard let indexPath = interactingItemIndexPath,
            let cell = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell),
            let leftIndex = cell.leftIndex
            else { return }
        
        let leftProductLayout = product.productLayouts[leftIndex]
        
        let pasteBoard = UIPasteboard(name: UIPasteboardName("ly.kite.photobook.rearrange"), create: true)
        
        guard let leftData = try? PropertyListEncoder().encode(leftProductLayout) else {
            fatalError("Photobook: encoding of product layout failed")
        }
        pasteBoard?.setItems([["ly.kite.photobook.productLayout" : leftData]])
        
        if !leftProductLayout.layout.isDoubleLayout, let rightIndex = cell.rightIndex {
            let rightProductLayout = product.productLayouts[rightIndex]
            guard let rightData = try? PropertyListEncoder().encode(rightProductLayout) else {
                fatalError("Photobook: encoding of product layout failed")
            }
            pasteBoard?.addItems([["ly.kite.photobook.productLayout" : rightData]])
        }
    }
    
    @objc private func pastePages() {
        guard product.isAddingPagesAllowed else {
            showNotAllowedToAddMorePagesAlert()
            return
        }
        
        guard let indexPath = interactingItemIndexPath,
            let pasteBoard = UIPasteboard(name: UIPasteboardName("ly.kite.photobook.rearrange"), create: true),
            let leftData = pasteBoard.items.first?["ly.kite.photobook.productLayout"] as? Data,
            let leftProductLayout = try? PropertyListDecoder().decode(ProductLayout.self, from: leftData)
            else { return }
        
        var productLayouts = [leftProductLayout]
        
        if pasteBoard.items.count > 1,
            let rightData = pasteBoard.items.last?["ly.kite.photobook.productLayout"] as? Data,
            let rightProductLayout = try? PropertyListDecoder().decode(ProductLayout.self, from: rightData) {
            productLayouts.append(rightProductLayout)
        }
        
        guard let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex else { return }
                
        // Need to clear the interacting index path before reloading or the pages will apear blank
        interactingItemIndexPath = nil
        
        // Insert new page above the tapped one
        product.addPages(at: index, pages: productLayouts)
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCells()
        })
        
        Analytics.shared.trackAction(.pastedPages)
        
    }
    
    @objc private func deletePages() {
        guard let indexPath = interactingItemIndexPath,
            let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex
            else { return }
        
        guard product.isRemovingPagesAllowed else {
            let alertController = UIAlertController(title: NSLocalizedString("Photobook/CannotDeleteAlertTitle", value: "Cannot Delete Page", comment: "Alert title letting the user know they can't delete a page from the book"), message: NSLocalizedString("Photobook/CannotDeleteAlertMessage", value: "Your photo book currently contains the minimum number of pages allowed", comment: "Alert message letting the user know they can't delete a page from the book"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let productLayout = product.productLayouts[index]
        
        product.deletePages(for: productLayout)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCells()
        })
        
        Analytics.shared.trackAction(.deletedPages)
        
    }
    
    @objc private func menuDidHide() {
        interactingItemIndexPath = nil
    }
    
    private func showMenu(at indexPath: IndexPath) {
        // Don't show the menu for the cover, fist and last page, when not rearranging and when we are already showing it
        guard isRearranging,
            interactingItemIndexPath == nil,
            let cell = collectionView.cellForItem(at: indexPath),
            indexPath.item != 0,
            indexPath.item != collectionView.numberOfItems(inSection: 1) - 1 // Last Page
            else { return }
        UIMenuController.shared.setTargetRect(cell.frame, in: collectionView)
        interactingItemIndexPath = indexPath
        
        let pasteBoard = UIPasteboard(name: UIPasteboardName("ly.kite.photobook.rearrange"), create: true)
        
        var menuItems = [UIMenuItem]()
        menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemCutTitle", value: "Cut", comment: "Cut/Paste interaction"), action: #selector(cutPages)))
        menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemCopyTitle", value: "Copy", comment: "Copy/Paste interaction"), action: #selector(copyPages)))
        if (pasteBoard?.items.count ?? 0) > 0 {
            menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemPasteTitle", value: "Paste", comment: "Copy/Paste interaction"), action: #selector(pastePages)))
        }
        menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemDeleteTitle", value: "Delete", comment: "Delete a page from the photobook"), action: #selector(deletePages)))
        
        UIMenuController.shared.menuItems = menuItems
        UIMenuController.shared.setMenuVisible(true, animated: true)
    }
    
    // MARK: - Drag and Drop
    
    private func deleteProposalCell(enableFeedback: Bool) {
        guard let indexPath = proposedDropIndexPath else { return }
        proposedDropIndexPath = nil
        collectionView.deleteItems(at: [indexPath])
        
        if enableFeedback{
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
        guard var sourceIndexPath = interactingItemIndexPath, let draggingView = draggingView else { return }
        
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
        
        UIView.animate(withDuration: Constants.dropAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
            draggingView.transform = CGAffineTransform(translationX: draggingView.transform.tx, y: draggingView.transform.ty)
            draggingView.frame.origin = CGPoint(x: self.collectionView.frame.origin.x + Constants.cellSideMargin * Constants.rearrangeScale, y: destinationY)
            draggingView.layer.shadowRadius = 0
            draggingView.layer.shadowOpacity = 0
        }, completion: { _ in
            // Unhide the book if we're returning to the original position
            sourceCell?.isVisible = true
            
            draggingView.removeFromSuperview()
            self.draggingView = nil
            self.interactingItemIndexPath = nil
            
            if let insertingIndexPath = self.insertingIndexPath, let cell = self.collectionView.cellForItem(at: insertingIndexPath) as? PhotobookCollectionViewCell {
                cell.isVisible = true
                cell.backgroundColor = UIColor(red:0.85, green:0.86, blue:0.86, alpha:1)
                self.insertingIndexPath = nil
            }
            
            if destinationIndexPath == sourceIndexPath {
                self.showMenu(at: sourceIndexPath)
            }
        })
        
        if destinationIndexPath != sourceIndexPath,
            let sourceProductLayoutIndex = product.productLayoutIndex(for: sourceIndexPath.item) {
            
            // Because we show a placeholder graphic where the drop proposal is, we get the destination index from the previous page
            let previousIndexPath = IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 1), section: destinationIndexPath.section)
            let previousCell = (collectionView.cellForItem(at: previousIndexPath) as? PhotobookCollectionViewCell)
            
            guard let destinationProductLayoutIndex = previousCell?.leftIndex ?? previousCell?.rightIndex else { return }
            
            product.moveLayout(from: sourceProductLayoutIndex, to: destinationProductLayoutIndex)
            
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
            snapshot.transform = CGAffineTransform(scaleX: Constants.dragLiftScale, y: Constants.dragLiftScale)
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
            cell.loadPages()
        }
    }
    
    private func editPage(_ page: PhotobookPageView, at index: Int, frame: CGRect, containerView: UIView) {
        let modalNavigationController = photobookMainStoryboard.instantiateViewController(withIdentifier: "PageSetupNavigationController") as! UINavigationController
        if #available(iOS 11.0, *) {
            modalNavigationController.navigationBar.prefersLargeTitles = false
        }

        let barType = (navigationController?.navigationBar as? PhotobookNavigationBar)?.barType
        
        let pageSetupViewController = modalNavigationController.viewControllers.first as! PageSetupViewController
        pageSetupViewController.assets = assets
        pageSetupViewController.pageIndex = index
        pageSetupViewController.album = album
        pageSetupViewController.albumManager = albumManager
        pageSetupViewController.assetPickerViewController = assetPickerViewController
        
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
            cell.isVisible = indexPath != interactingItemIndexPath && indexPath != insertingIndexPath
            cell.width = view.bounds.size.width - Constants.cellSideMargin * 2.0
            cell.clipsToBounds = false
            cell.delegate = self
            
            // First and last pages of the book are courtesy pages, no photos on them
            var leftIndex: Int? = nil
            var rightIndex: Int? = nil
            switch indexPath.item {
            case 0:
                rightIndex = 1
                cell.isFaded = isRearranging
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                leftIndex = product.productLayouts.count - 1
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
                cell.isFaded = false
            }
            
            cell.leftIndex = leftIndex
            cell.rightIndex = rightIndex
            cell.isPlusButtonVisible = indexPath.item != 0
            
            return cell
        }
    }    
}

extension PhotobookViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK: UICollectionViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavBar()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showMenu(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PhotobookCollectionViewCell {
            cell.loadPages()
        } else if let cell = cell as? PhotobookCoverCollectionViewCell {
            cell.loadCoverAndSpine()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath == proposedDropIndexPath {
            return CGSize(width: collectionView.bounds.width, height: Constants.proposalCellHeight)
        }

        let pageWidth = (view.bounds.width - Constants.cellSideMargin * 2.0 - PhotobookConstants.horizontalPageToCoverMargin * 2.0) / 2.0
        let pageHeight = pageWidth / product.template.aspectRatio

        // PhotoboookCollectionViewCell works when the collectionView uses dynamic heights by setting up the aspect ratio of its pages.
        // This however, causes problems with the drag & drop functionality and that is why the cell height is calculated by using the measurements set on the storyboard.
        return CGSize(width: view.bounds.width - Constants.cellSideMargin * 2.0, height: pageHeight + PhotobookConstants.verticalPageToCoverMargin * 2.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Reduces the space between cover and first page to match the one between pages
        if section == 0 {
            return UIEdgeInsetsMake(0.0, 0.0, -18.0, 0.0)
        }
        return .zero
    }
}

extension PhotobookViewController: PhotobookCoverCollectionViewCellDelegate {
    
    func didTapOnSpine(with rect: CGRect, in containerView: UIView) {
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
    // MARK: PhotobookCollectionViewCellDelegate
    
    func didTapOnPage(_ page: PhotobookPageView, at index: Int, frame: CGRect, in containerView: UIView) {
        editPage(page, at: index, frame: frame, containerView: containerView)
    }

    func didLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard let photobookFrameView = sender.view as? PhotobookFrameView else {
                fatalError("Long press failed to recognise the target view")
            }
            liftView(photobookFrameView)
        } else if sender.state == .ended {
            dropView()
            stopTimer()
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
        draggingView.transform = CGAffineTransform(translationX: translation.x, y: translation.y).scaledBy(x: Constants.dragLiftScale, y: Constants.dragLiftScale)
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
            
            scrollingTimer = Timer(timeInterval: screenRefreshRate, repeats: true, block: { [weak welf = self] timer in
                guard welf != nil else { return }
                if welf!.collectionView.contentOffset.y + welf!.collectionView.frame.size.height + (welf!.navigationController?.navigationBar.frame.maxY ?? 0) - Constants.proposalCellHeight < welf!.collectionView.contentSize.height {
                    welf!.collectionView.contentOffset = CGPoint(x: welf!.collectionView.contentOffset.x, y: welf!.collectionView.contentOffset.y + Constants.autoScrollOffset);
                    if let gesture = welf!.currentlyPanningGesture{
                        welf!.didPan(gesture)
                    }
                }
            })
        }
        else if (draggingView.frame.origin.y + draggingView.frame.size.height / 2.0 < view.frame.size.height * Constants.autoScrollTopScreenThreshold) {
            guard scrollingTimer == nil else { return }
            scrollingTimer = Timer(timeInterval: screenRefreshRate, repeats: true, block: { [weak welf = self] _ in
                guard welf != nil else { return }
                if welf!.collectionView.contentOffset.y > -(welf!.navigationController?.navigationBar.frame.maxY ?? 0) {
                    welf!.collectionView.contentOffset = CGPoint(x: welf!.collectionView.contentOffset.x, y: welf!.collectionView.contentOffset.y - Constants.autoScrollOffset);
                }
            })
        }
        else {
            stopTimer()
        }
        
        if let timer = scrollingTimer {
            RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        }
    }
    
    private func showNotAllowedToAddMorePagesAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("Photobook/TooManyPagesAlertTitle", value: "Too many pages", comment: "Alert title informing the user that they have reached the maximum number of pages"), message: NSLocalizedString("Photobook/TooManyPagesAlertMessage", value: "You cannot add any more pages to your photobook", comment: "Alert message informing the user that they have reached the maximum number of pages"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func didTapOnPlusButton(at spreadIndex: Int) {
        guard product.isAddingPagesAllowed else {
            showNotAllowedToAddMorePagesAlert()
            return
        }
        
        let indexPath = IndexPath(item: spreadIndex, section: 1)
        
        guard let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex else { return }
        
        // Insert new page above the tapped one
        product.addDoubleSpread(at: index)
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCells()
        })
        
        Analytics.shared.trackAction(.addedPages)
        
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return isRearranging && !isDragging
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
        
        collectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
        
        spineTextEditingViewController.animateOff {
            self.dismiss(animated: false, completion: nil)
        }
    }
}

