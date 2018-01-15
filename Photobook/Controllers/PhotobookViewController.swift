//
//  PhotobookViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookViewController: UIViewController {
    
    private struct Constants {
        static let rearrageScale: CGFloat = 0.8
        static let cellSideMargin: CGFloat = 10.0
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
    var selectedAssetsManager: SelectedAssetsManager?
    private var titleButton = UIButton()
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    var titleLabel: UILabel?
    private var interactingItemIndexPath: IndexPath?
    private var proposedDropIndexPath: IndexPath?
    private var isRearranging = false
    private var draggingView: UIView?
    private var isDragging = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // Remove pasteboard so that we avoid edge-cases with stale or inconsistent data
        UIPasteboard.remove(withName: UIPasteboardName("ly.kite.photobook.rearrange"))
        
        guard let photobook = ProductManager.shared.products?.first else {
            loadProducts()
            return
        }
        
        setup(with: photobook)
        
        collectionViewBottomConstraint.constant = -self.view.frame.height * (reverseRearrageScale - 1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let insets: UIEdgeInsets
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
        } else {
            insets = .zero
        }
        
        let bottomInset = isRearranging ? (ctaButtonContainer.frame.size.height - insets.bottom) * reverseRearrageScale : ctaButtonContainer.frame.size.height - insets.bottom - collectionViewBottomConstraint.constant
        
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
        if let size = collectionView.visibleCells.first?.frame.size {
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = size
        }
        
        isRearranging = !isRearranging
        
        if isRearranging{
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.collectionView.transform = CGAffineTransform(translationX: 0, y: -self.collectionView.frame.size.height * (1.0-Constants.rearrageScale)/2.0).scaledBy(x: 0.8, y: 0.8)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            sender.title = NSLocalizedString("Photobook/DoneButtonTitle", value: "Done", comment: "Done button title")
        } else{
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.collectionView.transform = .identity
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            sender.title = NSLocalizedString("Photobook/RearrangeButtonTitle", value: "Rearrange", comment: "Rearrange button title")
        }
        
        // Update drag interaction enabled status
        for cell in collectionView.visibleCells{
            guard let photobookCell = cell as? PhotobookCollectionViewCell else { continue }
            photobookCell.setIsRearranging(isRearranging)
        }
    }
    
    @IBAction private func didTapCheckout(_ sender: UIButton) {
        print("Tapped Checkout")
    }
    
    @IBAction private func didTapOnSpine(_ sender: UITapGestureRecognizer) {
        print("Tapped on spine")
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    private func updateVisibleCells() {
        for cell in collectionView.visibleCells {
            guard let photobookCell = cell as? PhotobookCollectionViewCell else { continue }
            if collectionView.indexPath(for: cell)?.item != 0 {
                photobookCell.plusButton.isHidden = !ProductManager.shared.isAddingPagesAllowed
            }
        }
    }
    
    // MARK: UIMenuController actions
    
    @objc func copyPages() {
        guard let indexPath = interactingItemIndexPath,
            let cell = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell),
            let leftIndex = cell.leftPageView.index
            else { return }
        
        let leftProductLayout = ProductManager.shared.productLayouts[leftIndex]
        
        let pasteBoard = UIPasteboard(name: UIPasteboardName("ly.kite.photobook.rearrange"), create: true)
        
        guard let leftData = try? PropertyListEncoder().encode(leftProductLayout) else {
            fatalError("Photobook: encoding of product layout failed")
        }
        pasteBoard?.setItems([["ly.kite.photobook.productLayout" : leftData]])
        
        if let rightIndex = cell.rightPageView?.index {
            let rightProductLayout = rightIndex
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
        
        guard let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftPageView.index else { return }
                
        // Need to clear the interacting index path before reloading or the pages will apear blank
        interactingItemIndexPath = nil
        
        // Insert new page above the tapped one
        ProductManager.shared.addPages(at: index, pages: productLayouts)
        collectionView.insertItems(at: [indexPath])
        updateVisibleCells()
    }
    
    @objc func deletePages() {
        guard let indexPath = interactingItemIndexPath,
            let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftPageView.index
            else { return }
        
        let productLayout = ProductManager.shared.productLayouts[index]
        
        ProductManager.shared.deletePage(at: productLayout)
        collectionView.deleteItems(at: [indexPath])
        updateVisibleCells()
    }
    
    @objc func menuDidHide() {
            interactingItemIndexPath = nil
    }
    
    @objc func handleLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard let bookView = sender.view as? PhotobookView else { return }
            liftView(bookView)
        } else if sender.state == .ended {
            dropView()
        }
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            isDragging = true
        } else if sender.state == .ended {
            isDragging = false
        }
        guard let draggingView = draggingView, sender.state == .changed else { return }
        
        let translation = sender.translation(in: view)
        draggingView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1).translatedBy(x: translation.x, y: translation.y)
        
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
        
        // Clear proposed drop index path if we are to drop:
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
            deleteProposalCell(enableFeedback: false)
            insertProposalCell(proposedIndexPath)
        }, completion: nil)
        
        
    }
    
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
        guard let sourceIndexPath = interactingItemIndexPath,
            let draggingView = self.draggingView
            else { return }
        
        let sourceCell = (collectionView.cellForItem(at: sourceIndexPath) as? PhotobookCollectionViewCell)
        
        let destinationIndexPath = proposedDropIndexPath ?? sourceIndexPath
        let movingDown = sourceIndexPath.item < destinationIndexPath.item
        guard let destinationCell = collectionView.cellForItem(at: IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 0), section: destinationIndexPath.section)) else { return }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            draggingView.transform = CGAffineTransform(translationX: draggingView.transform.tx, y: draggingView.transform.ty)
            draggingView.frame.origin = self.collectionView.convert(destinationCell.frame, to: self.view).origin
            draggingView.layer.shadowRadius = 0
            draggingView.layer.shadowOpacity = 0
        }, completion: { _ in
            // Unhide the book if we're returning to the original position
            sourceCell?.obscuringView.isHidden = true
            
            draggingView.removeFromSuperview()
            self.draggingView = nil
            self.interactingItemIndexPath = nil
        })
        
        if destinationIndexPath != sourceIndexPath,
            var sourceProductLayoutIndex = sourceCell?.bookView.leftPageView.index{
            
            let sourceProductLayout = ProductManager.shared.productLayouts[sourceProductLayoutIndex]
            
            // Because we show a placeholder graphic where the drop proposal is, we get the destination index from the previous page
            let previousIndexPath = IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 1), section: destinationIndexPath.section)
            let previousCell = (collectionView.cellForItem(at: previousIndexPath) as? PhotobookCollectionViewCell)
            
            guard let destinationProductLayoutIndex = previousCell?.leftPageView?.index ?? previousCell?.rightPageView?.index else { return }
            
            // Depending of if we're moving up or down, we will have to move either the left layout first or the second so that we don't mess up the indexes
            if  movingDown{
                if !sourceProductLayout.layout.isDoubleLayout {
                    ProductManager.shared.productLayouts.move(sourceProductLayoutIndex + 1, destinationProductLayoutIndex + 1)
                }
                ProductManager.shared.productLayouts.move(sourceProductLayoutIndex, destinationProductLayoutIndex)
            }
            else {
                if let previousCellIndex = previousCell?.leftPageView.index, ProductManager.shared.productLayouts[previousCellIndex].layout.isDoubleLayout {
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
            
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: [IndexPath(item: destinationIndexPath.item + (movingDown ? -1 : 0), section: destinationIndexPath.section)])
                deleteProposalCell(enableFeedback: false)
                if sourceCell != nil, let indexPath = collectionView.indexPath(for: sourceCell!){
                    collectionView.deleteItems(at: [IndexPath(item: indexPath.item + (movingDown ? 0 : 1), section: indexPath.section)])
                }
            }, completion: { _ in
                self.updateVisibleCellIndexes()
            })
        }
    }
    
    func liftView(_ bookView: PhotobookView) {
        guard let productLayoutIndex = bookView.leftPageView.index,
            let foldIndex = ProductManager.shared.foldIndex(for: productLayoutIndex),
            foldIndex != collectionView.numberOfItems(inSection: 1) - 1
            else { return }
        
        interactingItemIndexPath = IndexPath(item: foldIndex, section: 1)
        guard let snapshot = bookView.snapshotView(afterScreenUpdates: true),
        let bookSuperview = bookView.superview else { return }
        
        draggingView = snapshot
        view.addSubview(snapshot)
        snapshot.frame = bookSuperview.convert(bookView.frame, to: view)
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            snapshot.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            snapshot.layer.shadowRadius = 10
            snapshot.layer.shadowOpacity = 0.5
        }, completion: { _ in
            (self.collectionView.cellForItem(at: IndexPath(item: foldIndex, section: 1)) as? PhotobookCollectionViewCell)?.obscuringView.isHidden = false
        })
    }
    
    func updateVisibleCellIndexes() {
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                let productLayoutIndex = ProductManager.shared.productLayoutIndex(for: indexPath.item),
                let cell = cell as? PhotobookCollectionViewCell
                else { continue }
            
            cell.leftPageView.index = productLayoutIndex
            cell.rightPageView?.index = productLayoutIndex + 1
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
        switch section{
        case 1:
            // TODO: division by 2 problematic with full-width pages
            return (ProductManager.shared.productLayouts.count + 1) / 2 + (proposedDropIndexPath != nil ? 1 : 0)
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //Don't bother calculating the exact size, request a slightly larger size
        //TODO: Full width pages shouldn't divide by 2
        let imageSize = CGSize(width: collectionView.frame.size.width / 2.0, height: collectionView.frame.size.width / 2.0)
        
        switch indexPath.section{
        case 0:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as? PhotobookCoverCollectionViewCell
                else { return UICollectionViewCell() }
            
            cell.leftPageView.index = 0
            cell.leftPageView.delegate = self
            cell.leftPageView.load(size: imageSize)
            
            return cell
        default:
            if let proposedDropIndexPath = proposedDropIndexPath, indexPath.item == proposedDropIndexPath.item {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "proposalCell", for: indexPath)
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as! PhotobookCollectionViewCell
            
            cell.obscuringView.isHidden = indexPath != interactingItemIndexPath
            cell.delegate = self

            cell.rightPageView?.delegate = self
            cell.leftPageView.delegate = self

            // First and last pages of the book are courtesy pages, no photos on them
            switch indexPath.item{
            case 0:
                cell.leftPageView.index = nil
                cell.rightPageView?.index = 1
                cell.plusButton.isHidden = true
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                cell.leftPageView.index = ProductManager.shared.productLayouts.count - 1
                cell.rightPageView?.index = nil
                cell.plusButton.isHidden = false
            default:
                guard let index = ProductManager.shared.productLayoutIndex(for: indexPath.item) else { return cell }
                cell.leftPageView.index = index
                if indexPath.item * 2 + 1 < ProductManager.shared.productLayouts.count {
                    cell.rightPageView?.index = index + 1
                }
                cell.plusButton.isHidden = false
                
                // Add gestures required for drag and drop
                if cell.bookView.gestureRecognizers?.count ?? 0 == 0{
                    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
                    longPressGesture.delegate = self
                    cell.bookView.addGestureRecognizer(longPressGesture)
                    
                    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
                    panGesture.delegate = self
                    panGesture.maximumNumberOfTouches = 1
                    cell.bookView.addGestureRecognizer(panGesture)
                }
                cell.setIsRearranging(isRearranging)
            }

            cell.leftPageView.load(size: imageSize)
            cell.rightPageView?.load(size: imageSize)
            
            cell.plusButton.isHidden = !ProductManager.shared.isAddingPagesAllowed

            return cell
        
        }
    }
}

extension PhotobookViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK: UICollectionViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navigationController?.navigationBar as? PhotobookNavigationBar else { return }
        
        navBar.effectView.alpha = scrollView.contentOffset.y <= -(navigationController?.navigationBar.frame.maxY ?? 0)  ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let product = ProductManager.shared.product else { return .zero }
        
        if indexPath == proposedDropIndexPath, let size = collectionView.visibleCells.first?.frame.size {
            return CGSize(width: size.width, height: size.width * (32.0/406.0))
        } else {
            // TODO: Change this when we have a way to generate the book backgrounds.
            // ie, use the proper margins if it's dynamic or if we're using images, use the image dimensions
            let width = view.frame.size.width - 20
            return CGSize(width: width, height: width / (product.pageSizeRatio * 2.0))
        }
    }
    
}

extension PhotobookViewController: PhotobookPageViewDelegate {
    // MARK: PhotobookViewDelegate

    func didTapOnPage(index: Int) {
        let pageSetupViewController = storyboard?.instantiateViewController(withIdentifier: "PageSetupViewController") as! PageSetupViewController
        pageSetupViewController.selectedAssetsManager = selectedAssetsManager
        pageSetupViewController.productLayout = ProductManager.shared.productLayouts[index].shallowCopy()
        pageSetupViewController.pageIndex = index
        if index == 0 { // Cover
            pageSetupViewController.pageSizeRatio = ProductManager.shared.product!.coverSizeRatio
            pageSetupViewController.availableLayouts = ProductManager.shared.currentCoverLayouts()
        } else {
            pageSetupViewController.pageSizeRatio = ProductManager.shared.product!.pageSizeRatio
            pageSetupViewController.availableLayouts = ProductManager.shared.currentLayouts()
        }
        pageSetupViewController.delegate = self
        present(pageSetupViewController, animated: true, completion: nil)
    }
}

extension PhotobookViewController: PageSetupDelegate {
    // MARK: PageSetupDelegate
    
    func didFinishEditingPage(_ index: Int, productLayout: ProductLayout, saving: Bool) {
        if saving {
            ProductManager.shared.productLayouts[index] = productLayout
            collectionView.reloadData()
        }
        dismiss(animated: true, completion: nil)
    }
}

extension PhotobookViewController: PhotobookCollectionViewCellDelegate {
    // MARK: PhotobookCollectionViewCellDelegate
    
    func didTapOnPlusButton(at foldIndex: Int) {
        let indexPath = IndexPath(item: foldIndex, section: 1)
        
        guard let index = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftPageView.index else { return }
        
        // Insert new page above the tapped one
        ProductManager.shared.addPages(at: index)
        collectionView.insertItems(at: [indexPath])
    }
}

extension PhotobookViewController: UIGestureRecognizerDelegate {
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return isRearranging && !isDragging
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.view === gestureRecognizer.view || draggingView == nil
    }
}
