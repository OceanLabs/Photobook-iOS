//
//  PhotobookViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookViewController: UIViewController, PhotobookNavigationBarDelegate {
    
    private struct Constants {
        static let rearrageScale: CGFloat = 0.8
        static let cellSideMargin: CGFloat = 10.0
        static let rearrangeAnimationDuration: TimeInterval = 0.25
        static let dragLiftScale: CGFloat = 1.1
        static let autoScrollTopScreenThreshold: CGFloat = 0.2
        static let autoScrollBottomScreenThreshold: CGFloat = 0.9
        static let autoScrollOffset: CGFloat = 10.0
        static let dragLiftAnimationDuration: TimeInterval = 0.15
        static let dropAnimationDuration: TimeInterval = 0.3
        static let proposalCellHeight: CGFloat = 30.0
    }
    private var reverseRearrageScale: CGFloat {
        return 1 + (1 - Constants.rearrageScale) / Constants.rearrageScale
    }

    @IBOutlet weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var ctaButtonContainer: UIView!
    
    var photobookNavigationBarType: PhotobookNavigationBarType = .clear
    
    var selectedAssetsManager: SelectedAssetsManager?
    private var titleButton = UIButton()
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    var titleLabel: UILabel?
    private var interactingItemIndexPath: IndexPath?
    private var proposedDropIndexPath: IndexPath?
    private var insertingIndexPath: IndexPath?
    private var isRearranging = false
    private var draggingView: UIView?
    private var isDragging = false
    private weak var currentlyPanningGesture: UIPanGestureRecognizer?
    private var scrollingTimer: Timer?
    private var photobookNeedsRedrawing = false
    
    // Scrolling at 60Hz when we are dragging looks good enough and avoids having to normalize the scroll offset
    private lazy var screenRefreshRate: Double = 1.0 / 60.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // Remove pasteboard so that we avoid edge-cases with stale or inconsistent data
        UIPasteboard.remove(withName: UIPasteboardName("ly.kite.photobook.rearrange"))
        
        collectionViewBottomConstraint.constant = -self.view.frame.height * (reverseRearrageScale - 1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
        
        guard let photobook = ProductManager.shared.products?.first else {
            loadProducts()
            return
        }
        
        setup(with: photobook)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Reset the var after a possible colour change
        photobookNeedsRedrawing = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        (tabBarController?.tabBar as? PhotobookTabBar)?.isBackgroundHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let insets: UIEdgeInsets
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
        } else {
            insets = .zero
        }
        
        let bottomInset = isRearranging ? ctaButtonContainer.frame.size.height * reverseRearrageScale - insets.bottom : ctaButtonContainer.frame.size.height - insets.bottom - collectionViewBottomConstraint.constant
        
        let topInset = isRearranging ? (navigationController?.navigationBar.frame.maxY ?? 0) * (1 - Constants.rearrageScale) : 0
                
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: collectionView.contentInset.left, bottom: bottomInset, right: collectionView.contentInset.right)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
    }
    
    private func setup(with photobook: Photobook) {
        guard let assets = selectedAssetsManager?.selectedAssets else {
            // Should never really reach here
            emptyScreenViewController.show(message: NSLocalizedString("Photobook/NoPhotosSelected", value: "No photos selected", comment: "No photos selected error message"))
            return
        }
        
        ProductManager.shared.setPhotobook(photobook, withAssets: assets)
        setupTitleView()
        
        if emptyScreenViewController.parent != nil {
            collectionView.reloadData()
            emptyScreenViewController.hide(animated: true)
        }
    }
    
    private func loadProducts() {
        emptyScreenViewController.show(message: NSLocalizedString("Photobook/Loading", value: "Loading products", comment: "Loading products screen message"), activity: true)
        ProductManager.shared.initialise(completion: { [weak welf = self] (error: Error?) in
            guard let photobook = ProductManager.shared.products?.first,
                error == nil
                else {
                    welf?.emptyScreenViewController.show(message: error?.localizedDescription ?? "Error", buttonTitle: NSLocalizedString("Photobook/RetryLoading", value: "Retry", comment: "Retry loading products button"), buttonAction: {
                        welf?.loadProducts()
                    })
                    return
            }
            
            welf?.setup(with: photobook)
        })
    }
    
    private func setupTitleView() {
        titleButton = UIButton()
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleButton.setTitleColor(.black, for: .normal)
        titleButton.setTitle(ProductManager.shared.product?.name, for: .normal)
        titleButton.setImage(UIImage(named:"chevron-down"), for: .normal)
        titleButton.semanticContentAttribute = .forceRightToLeft
        titleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -5)
        titleButton.addTarget(self, action: #selector(didTapOnTitle), for: .touchUpInside)
        navigationItem.titleView = titleButton
    }
    
    @objc private func didTapOnTitle() {
        guard let photobooks = ProductManager.shared.products else { return }
        
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("Photobook/ChangeSizeTitle", value: "Changing the size keeps your layout intact", comment: "Information when the user wants to change the photo book's size"), preferredStyle: .actionSheet)
        for photobook in photobooks{
            alertController.addAction(UIAlertAction(title: photobook.name, style: .default, handler: { [weak welf = self] (_) in
                welf?.titleButton.setTitle(photobook.name, for: .normal)
                
                ProductManager.shared.setPhotobook(photobook)
                self.collectionView.reloadData()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("General/UI", value: "Cancel", comment: "Cancel a change"), style: .default, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }

    @IBAction private func didTapRearrange(_ sender: UIBarButtonItem) {
        isRearranging = !isRearranging
        
        if isRearranging{
            UIView.animate(withDuration: Constants.rearrangeAnimationDuration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.collectionView.transform = CGAffineTransform(translationX: 0, y: -self.collectionView.frame.size.height * (1.0-Constants.rearrageScale)/2.0).scaledBy(x: Constants.rearrageScale, y: Constants.rearrageScale)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            sender.title = NSLocalizedString("Photobook/DoneButtonTitle", value: "Done", comment: "Done button title")
        } else{
            UIView.animate(withDuration: Constants.rearrangeAnimationDuration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.collectionView.transform = .identity
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            sender.title = NSLocalizedString("Photobook/RearrangeButtonTitle", value: "Rearrange", comment: "Rearrange button title")
        }
        
        // Update drag interaction enabled status
        for cell in collectionView.visibleCells {
            guard let photobookCell = cell as? PhotobookCollectionViewCell else { continue }
            photobookCell.setIsRearranging(isRearranging)
        }
    }
    
    @IBAction private func didTapOnSpine(_ sender: UITapGestureRecognizer) {
        print("Tapped on spine")
    }
    
    @IBAction func didTapCheckout(_ sender: Any) {
        guard draggingView == nil else { return }
        performSegue(withIdentifier: "CheckoutSegue", sender: nil)
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    private func updateVisibleCells() {
        for cell in collectionView.visibleCells {
            guard let photobookCell = cell as? PhotobookCollectionViewCell else { continue }
            photobookCell.isPlusButtonVisible = ProductManager.shared.isAddingPagesAllowed && collectionView.indexPath(for: cell)?.item != 0
        }
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
    
    deinit {
        stopTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIMenuController actions
    
    @objc func copyPages() {
        guard let indexPath = interactingItemIndexPath,
            let cell = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell),
            let leftIndex = cell.leftIndex
            else { return }
        
        let leftProductLayout = ProductManager.shared.productLayouts[leftIndex]
        
        let pasteBoard = UIPasteboard(name: UIPasteboardName("ly.kite.photobook.rearrange"), create: true)
        
        guard let leftData = try? PropertyListEncoder().encode(leftProductLayout) else {
            fatalError("Photobook: encoding of product layout failed")
        }
        pasteBoard?.setItems([["ly.kite.photobook.productLayout" : leftData]])
        
        if let rightIndex = cell.rightIndex {
            let rightProductLayout = ProductManager.shared.productLayouts[rightIndex]
            guard let rightData = try? PropertyListEncoder().encode(rightProductLayout) else {
                fatalError("Photobook: encoding of product layout failed")
            }
            pasteBoard?.addItems([["ly.kite.photobook.productLayout" : rightData]])
        }
    }
    
    @objc func pastePages() {
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
        ProductManager.shared.addPages(at: index, pages: productLayouts)
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCellIndexes()
        })
        
        updateVisibleCells()
    }
    
    @objc func deletePages() {
        guard let indexPath = interactingItemIndexPath,
            let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex
            else { return }
        
        let productLayout = ProductManager.shared.productLayouts[index]
        
        ProductManager.shared.deletePage(at: productLayout)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCellIndexes()
        })
        
        self.updateVisibleCells()
    }
    
    @objc func menuDidHide() {
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
        menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemCopyTitle", value: "Copy", comment: "Copy/Paste interaction"), action: #selector(copyPages)))
        if ProductManager.shared.isAddingPagesAllowed && (pasteBoard?.items.count ?? 0) > 0 {
            menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemPasteTitle", value: "Paste", comment: "Copy/Paste interaction"), action: #selector(pastePages)))
        }
        if ProductManager.shared.isRemovingPagesAllowed {
            menuItems.append(UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemDeleteTitle", value: "Delete", comment: "Delete a page from the photobook"), action: #selector(deletePages)))
        }
        
        UIMenuController.shared.menuItems = menuItems
        UIMenuController.shared.setMenuVisible(true, animated: true)
    }
    
    // MARK: - Drag and Drop
    
    func deleteProposalCell(enableFeedback: Bool) {
        guard let indexPath = proposedDropIndexPath else { return }
        proposedDropIndexPath = nil
        collectionView.deleteItems(at: [indexPath])
        
        if enableFeedback{
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    func insertProposalCell(_ indexPath: IndexPath) {
        proposedDropIndexPath = indexPath
        collectionView.insertItems(at: [indexPath])
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()        
    }
    
    func dropView() {
        guard var sourceIndexPath = interactingItemIndexPath,
            let draggingView = self.draggingView
            else { return }
        
        let sourceCell = (collectionView.cellForItem(at: sourceIndexPath) as? PhotobookCollectionViewCell)
        
        let destinationIndexPath = proposedDropIndexPath ?? sourceIndexPath
        let movingDown = sourceIndexPath.item < destinationIndexPath.item
                
        let destinationY: CGFloat
        if let destinationCell = collectionView.cellForItem(at: IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 0), section: destinationIndexPath.section)) {
            destinationY = self.collectionView.convert(destinationCell.frame, to: self.view).origin.y
        } else if draggingView.frame.origin.y + draggingView.frame.height > view.frame.height / 2.0 {
            destinationY = -draggingView.frame.height
        } else {
            destinationY = view.frame.height + draggingView.frame.height
        }
        
        UIView.animate(withDuration: Constants.dropAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
            draggingView.transform = CGAffineTransform(translationX: draggingView.transform.tx, y: draggingView.transform.ty)
            draggingView.frame.origin = CGPoint(x: self.collectionView.frame.origin.x + Constants.cellSideMargin * Constants.rearrageScale, y: destinationY)
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
        })
        
        if destinationIndexPath != sourceIndexPath,
            var sourceProductLayoutIndex = ProductManager.shared.productLayoutIndex(for: sourceIndexPath.item + (movingDown ? 0 : -1)) {
            
            let sourceProductLayout = ProductManager.shared.productLayouts[sourceProductLayoutIndex]
            
            // Because we show a placeholder graphic where the drop proposal is, we get the destination index from the previous page
            let previousIndexPath = IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 1), section: destinationIndexPath.section)
            let previousCell = (collectionView.cellForItem(at: previousIndexPath) as? PhotobookCollectionViewCell)
            
            guard let destinationProductLayoutIndex = previousCell?.leftIndex ?? previousCell?.rightIndex else { return }
            
            // Depending of if we're moving up or down, we will have to move either the left layout first or the second so that we don't mess up the indexes
            if  movingDown{
                if !sourceProductLayout.layout.isDoubleLayout {
                    ProductManager.shared.productLayouts.move(sourceProductLayoutIndex + 1, destinationProductLayoutIndex + 1)
                }
                ProductManager.shared.productLayouts.move(sourceProductLayoutIndex, destinationProductLayoutIndex)
            }
            else {
                if let previousCellIndex = previousCell?.leftIndex, ProductManager.shared.productLayouts[previousCellIndex].layout.isDoubleLayout {
                    sourceProductLayoutIndex += 1
                }
                else {
                    sourceProductLayoutIndex += 2
                }
                
                ProductManager.shared.productLayouts.move(sourceProductLayoutIndex, destinationProductLayoutIndex)
                if !sourceProductLayout.layout.isDoubleLayout {
                    ProductManager.shared.productLayouts.move(sourceProductLayoutIndex + 1, destinationProductLayoutIndex + 1)
                }
            }
            
            self.interactingItemIndexPath = nil
            
            let insertingIndexPath = IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 0), section: destinationIndexPath.section)
            self.insertingIndexPath = insertingIndexPath
            
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: [insertingIndexPath])
                deleteProposalCell(enableFeedback: false)
                collectionView.deleteItems(at: [IndexPath(item: sourceIndexPath.item + (movingDown ? 0 : 1), section: sourceIndexPath.section)])
            }, completion: { _ in
                self.updateVisibleCellIndexes()
            })
        }
    }
    
    func liftView(_ photobookFrameView: PhotobookFrameView) {
        guard let productLayoutIndex = photobookFrameView.leftPageView.index,
            let foldIndex = ProductManager.shared.spreadIndex(for: productLayoutIndex),
            foldIndex != collectionView.numberOfItems(inSection: 1) - 1
            else { return }
        
        interactingItemIndexPath = IndexPath(item: foldIndex, section: 1)
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
            (self.collectionView.cellForItem(at: IndexPath(item: foldIndex, section: 1)) as? PhotobookCollectionViewCell)?.isVisible = false
        })
    }
    
    func updateVisibleCellIndexes() {
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                let productLayoutIndex = ProductManager.shared.productLayoutIndex(for: indexPath.item),
                let cell = cell as? PhotobookCollectionViewCell
                else { continue }

            cell.loadPages(leftIndex: productLayoutIndex, rightIndex: productLayoutIndex + 1)
        }
    }
}

extension PhotobookViewController: UICollectionViewDataSource {
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard ProductManager.shared.product != nil else { return 0 }
        
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 1:
            guard let lastFoldIndex = ProductManager.shared.spreadIndex(for: ProductManager.shared.productLayouts.count - 1) else { return 0 }
            return lastFoldIndex + 1 + (proposedDropIndexPath != nil ? 1 : 0)
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Don't bother calculating the exact size, request a slightly larger size
        let imageSize = CGSize(width: collectionView.frame.size.width / 2.0, height: collectionView.frame.size.width / 2.0)
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotobookCoverCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotobookCoverCollectionViewCell
            cell.imageSize = imageSize
            cell.width = (view.bounds.size.width - Constants.cellSideMargin * 2.0) / 2.0
            cell.delegate = self
            cell.loadCover(redrawing: photobookNeedsRedrawing)
            
            return cell
        default:
            if let proposedDropIndexPath = proposedDropIndexPath, indexPath.item == proposedDropIndexPath.item {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "ProposalCollectionViewCell", for: indexPath)
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotobookCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotobookCollectionViewCell
            cell.isVisible = indexPath != interactingItemIndexPath && indexPath != insertingIndexPath
            cell.imageSize = imageSize
            cell.width = view.bounds.size.width - Constants.cellSideMargin * 2.0
            cell.clipsToBounds = false
            
            cell.delegate = self
            cell.pageDelegate = self
            
            // First and last pages of the book are courtesy pages, no photos on them
            var leftIndex: Int? = nil
            var rightIndex: Int? = nil
            switch indexPath.item {
            case 0:
                rightIndex = 1
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                leftIndex = ProductManager.shared.productLayouts.count - 1
            default:
                let indexPathItem = indexPath.item - ((proposedDropIndexPath?.item ?? Int.max) < indexPath.item ? 1 : 0)
                guard let index = ProductManager.shared.productLayoutIndex(for: indexPathItem) else { return cell }
                leftIndex = index
                if index + 1 < ProductManager.shared.productLayouts.count {
                    rightIndex = index + 1
                }
                cell.setupGestures()
                cell.setIsRearranging(isRearranging)
                
                // Get a larger image if the layout is double width
                if ProductManager.shared.productLayouts[index].layout.isDoubleLayout {
                    cell.imageSize = CGSize(width: imageSize.width * 2.0, height: imageSize.height * 2.0)
                }
            }
            
            let leftLayout: ProductLayout? = leftIndex != nil ? ProductManager.shared.productLayouts[leftIndex!] : nil
            let rightLayout: ProductLayout? = rightIndex != nil ? ProductManager.shared.productLayouts[rightIndex!] : nil

            cell.loadPages(leftIndex: leftIndex, rightIndex: rightIndex, leftLayout: leftLayout, rightLayout: rightLayout, redrawing: photobookNeedsRedrawing)
            
            cell.isPlusButtonVisible = ProductManager.shared.isAddingPagesAllowed && indexPath.item != 0
            
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let product = ProductManager.shared.product else { return .zero }

        if indexPath == proposedDropIndexPath {
            return CGSize(width: collectionView.bounds.width, height: Constants.proposalCellHeight)
        }

        let pageWidth = ceil((view.bounds.width - Constants.cellSideMargin * 2.0 - PhotobookConstants.horizontalPageToCoverMargin * 2.0 - PhotobookConstants.pageDividerWidth) / 2.0)
        let pageHeight = ceil(pageWidth / product.aspectRatio)

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

extension PhotobookViewController: PhotobookPageViewDelegate {
    // MARK: PhotobookPageViewDelegate

    func didTapOnPage(index: Int) {
        let pageSetupViewController = storyboard?.instantiateViewController(withIdentifier: "PageSetupViewController") as! PageSetupViewController
        pageSetupViewController.selectedAssetsManager = selectedAssetsManager
        pageSetupViewController.pageIndex = index
        pageSetupViewController.delegate = self
        navigationController?.pushViewController(pageSetupViewController, animated: true)
    }
}

extension PhotobookViewController: PageSetupDelegate {
    // MARK: PageSetupDelegate
    
    func didFinishEditingPage(_ index: Int?, productLayout: ProductLayout?, color: ProductColor?) {
        if let index = index {
            if let productLayout = productLayout {
                ProductManager.shared.productLayouts[index] = productLayout
            }
            if let color = color {
                if index == 0 { // Cover
                    photobookNeedsRedrawing = ProductManager.shared.coverColor != color
                    ProductManager.shared.coverColor = color
                } else {
                    photobookNeedsRedrawing = ProductManager.shared.pageColor != color
                    ProductManager.shared.pageColor = color
                }
            }
            collectionView.reloadData()
        }
        navigationController?.popViewController(animated: true)
    }
}

extension PhotobookViewController: PhotobookCollectionViewCellDelegate {
    // MARK: PhotobookCollectionViewCellDelegate
    
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
    
    func didTapOnPlusButton(at foldIndex: Int) {
        let indexPath = IndexPath(item: foldIndex, section: 1)
        
        guard let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftIndex else { return }
        
        // Insert new page above the tapped one
        ProductManager.shared.addPages(at: index)
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: [indexPath])
        }, completion: { _ in
            self.updateVisibleCellIndexes()
        })
        
        self.updateVisibleCells()
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return isRearranging && !isDragging
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.view === gestureRecognizer.view || draggingView == nil
    }
}

