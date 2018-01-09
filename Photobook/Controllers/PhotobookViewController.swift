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
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet{
            collectionView.dropDelegate = self
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = UICollectionViewFlowLayoutAutomaticSize
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = CGSize(width: 100, height: 100)
        }
    }
    @IBOutlet private weak var ctaButtonContainer: UIView!
    var selectedAssetsManager: SelectedAssetsManager?
    private var titleButton = UIButton()
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    var titleLabel: UILabel?
    private var interactingItemIndexPath: IndexPath?
    private var proposedDropIndexPath: IndexPath?
    private var isRearranging = false {
        didSet{
            if isRearranging{
                UIView.animate(withDuration: 0.3, animations: {
                    self.collectionView.transform = CGAffineTransform(translationX: 0, y: -self.collectionView.frame.size.height * (1.0-Constants.rearrageScale)/2.0).scaledBy(x: 0.8, y: 0.8)
                    
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                })
            }
            else{
                UIView.animate(withDuration: 0.3, animations: {
                    self.collectionView.transform = .identity
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                })
            }
            
            // Update drag interaction enabled status
            for cell in collectionView.visibleCells{
                guard let photobookCell = cell as? PhotobookCollectionViewCell else { continue }
                photobookCell.setIsRearranging(isRearranging)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        // Remove pasteboard so that we avoid edge-cases with stale or inconsistent data
        UIPasteboard.remove(withName: UIPasteboardName("ly.kite.photobook.rearrange"))
        
        guard let assets = selectedAssetsManager?.selectedAssets else {
            // Should never really reach here
            emptyScreenViewController.show(message: NSLocalizedString("Photobook/NoPhotosSelected", value: "No photos selected", comment: "No photos selected error message"))
            return
        }
        
        guard let photobook = ProductManager.shared.products?.first else {
            emptyScreenViewController.show(message: NSLocalizedString("Photobook/Loading", value: "Loading products", comment: "Loading products screen message"), activity: true)
            ProductManager.shared.initialise(completion: { [weak welf = self] (error: Error?) in
                guard let photobook = ProductManager.shared.products?.first,
                    error == nil else {
                        // TODO: show emptyScreen with error and retry/back button
                        return
                }
                
                ProductManager.shared.setPhotobook(photobook, withAssets: assets)
                welf?.setupTitleView()
                welf?.collectionView.reloadData()
                welf?.emptyScreenViewController.hide(animated: true)
            })
            return
        }
        
        ProductManager.shared.setPhotobook(photobook, withAssets: assets)
        setupTitleView()
        
        collectionViewBottomConstraint.constant = -self.view.frame.height * (reverseRearrageScale - 1)
        
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bottomInset = isRearranging ? (ctaButtonContainer.frame.size.height - view.safeAreaInsets.bottom) * reverseRearrageScale : ctaButtonContainer.frame.size.height - view.safeAreaInsets.bottom - collectionViewBottomConstraint.constant
        
        let topInset = isRearranging ? (navigationController?.navigationBar.frame.maxY ?? 0) * (1 - Constants.rearrageScale) : 0
                
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: collectionView.contentInset.left, bottom: bottomInset, right: collectionView.contentInset.right)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
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
            let leftProductLayout = cell.leftPageView.productLayout
            else { return }
        
        let pasteBoard = UIPasteboard(name: UIPasteboardName("ly.kite.photobook.rearrange"), create: true)
        
        guard let leftData = try? PropertyListEncoder().encode(leftProductLayout) else {
            fatalError("Photobook: encoding of product layout failed")
        }
        pasteBoard?.setItems([["ly.kite.photobook.productLayout" : leftData]])
        
        if let rightProductLayout = cell.rightPageView?.productLayout {
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
        
        guard let productLayout = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftPageView.productLayout else { return }
        
        // Need to clear the interacting index path before reloading or the pages will apear blank
        interactingItemIndexPath = nil
        
        // Insert new page above the tapped one
        ProductManager.shared.addPages(above: productLayout, pages: productLayouts)
        collectionView.insertItems(at: [indexPath])
        updateVisibleCells()
    }
    
    @objc func deletePages() {
        guard let indexPath = interactingItemIndexPath,
            let productLayout = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftPageView.productLayout
            else { return }
        
        ProductManager.shared.deletePage(at: productLayout)
        collectionView.deleteItems(at: [indexPath])
        updateVisibleCells()
    }
    
    @objc func menuDidHide() {
            interactingItemIndexPath = nil
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
            return (ProductManager.shared.productLayouts.count + 1) / 2
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
            
            if let photobook = ProductManager.shared.product{
                cell.configurePageAspectRatio(photobook.coverSizeRatio)
            }
            
            cell.leftPageView.productLayout = ProductManager.shared.productLayouts[0]
            cell.leftPageView.delegate = self
            cell.leftPageView.load(size: imageSize)
            
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotobookCollectionViewCell
                else { return UICollectionViewCell() }
            
            cell.widthConstraint.constant = view.bounds.size.width - Constants.cellSideMargin * 2.0
            cell.obscuringView.isHidden = indexPath != interactingItemIndexPath
            cell.delegate = self
            
            if let photobook = ProductManager.shared.product{
                cell.configurePageAspectRatio(photobook.pageSizeRatio)
            }

            cell.rightPageView?.delegate = self
            cell.leftPageView.delegate = self

            // First and last pages of the book are courtesy pages, no photos on them
            switch indexPath.item{
            case 0:
                cell.leftPageView.productLayout = nil
                cell.rightPageView?.productLayout = ProductManager.shared.productLayouts[1]
                cell.plusButton.isHidden = true
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                cell.leftPageView.productLayout = ProductManager.shared.productLayouts[ProductManager.shared.productLayouts.count - 1]
                cell.rightPageView?.productLayout = nil
                cell.plusButton.isHidden = false
            default:
                cell.leftPageView.productLayout = ProductManager.shared.productLayouts[indexPath.item * 2]
                if indexPath.item * 2 + 1 < ProductManager.shared.productLayouts.count {
                    cell.rightPageView?.productLayout = ProductManager.shared.productLayouts[indexPath.item * 2 + 1]
                }
                cell.plusButton.isHidden = false
                
                // Add drag interaction
                if cell.bookView.interactions.count == 0{
                    let dragInteraction = UIDragInteraction(delegate: self)
                    cell.bookView.addInteraction(dragInteraction)
                    cell.clipsToBounds = false
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

extension PhotobookViewController: UICollectionViewDelegate {
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
    
}

extension PhotobookViewController: UIDragInteractionDelegate {
    // MARK: UIDragInteractionDelegate
    
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let bookView = interaction.view as? PhotobookView,
            let productLayout = bookView.leftPageView.productLayout,
            let foldIndex = ProductManager.shared.foldIndex(for: productLayout),
            foldIndex != collectionView.numberOfItems(inSection: 1) - 1
            else { return [] }
        
        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        guard let bookView = interaction.view as? PhotobookView,
            let productLayout = bookView.leftPageView.productLayout,
            let foldIndex = ProductManager.shared.foldIndex(for: productLayout),
            let cell = collectionView.cellForItem(at: IndexPath(item: foldIndex, section: 1)) as? PhotobookCollectionViewCell
            else { return }
        
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = cell.frame.size
        
        animator.addCompletion({(position) in
            if position == .end{
                cell.obscuringView.isHidden = false
            }
        })
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, prefersFullSizePreviewsFor session: UIDragSession) -> Bool {
        return true
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, sessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, previewForCancelling item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        guard let view = interaction.view else { return nil }
        return UITargetedDragPreview(view: view)
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
        guard let indexPath = interactingItemIndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell else { return }
        
        animator.addCompletion({(_) in
            cell.obscuringView.isHidden = true
        })
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        interactingItemIndexPath = nil

        guard let bookView = interaction.view as? PhotobookView,
            let productLayout = bookView.leftPageView.productLayout,
            let foldIndex = ProductManager.shared.foldIndex(for: productLayout),
            let cell = collectionView.cellForItem(at: IndexPath(item: foldIndex, section: 1)) as? PhotobookCollectionViewCell else { return }
        
        cell.obscuringView.isHidden = true
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        guard let bookView = interaction.view as? PhotobookView,
            let productLayout = bookView.leftPageView.productLayout,
            let foldIndex = ProductManager.shared.foldIndex(for: productLayout),
            foldIndex != collectionView.numberOfItems(inSection: 1) - 1
            else { return }
        
        interactingItemIndexPath = IndexPath(item: foldIndex, section: 1)
    }
    
}

extension PhotobookViewController: UICollectionViewDropDelegate {
    // MARK: UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal{
        
        // Prevent dragging to the same indexPath, the next, the cover and the first and last pages
        guard
            let draggingIndex = interactingItemIndexPath?.item,
            let dropIndexPath = destinationIndexPath,
            draggingIndex != dropIndexPath.item,
            draggingIndex + 1 != dropIndexPath.item,
            collectionView.cellForItem(at: dropIndexPath) as? PhotobookCollectionViewCell == nil,
            dropIndexPath.item != 0,
            dropIndexPath.item != collectionView.numberOfItems(inSection: 1) // Last Page
            else {
                return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
        }
        
        proposedDropIndexPath = dropIndexPath
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let sourceIndexPath = interactingItemIndexPath,
            var destinationIndexPath = proposedDropIndexPath,
            let sourceProductLayout = (collectionView.cellForItem(at: sourceIndexPath) as? PhotobookCollectionViewCell)?.bookView.leftPageView.productLayout,
            let sourceProductLayoutIndex = ProductManager.shared.productLayouts.index(where: { $0 === sourceProductLayout })
            else { return }
        
        // Because we show a placeholder graphic where we picked the source cell up, the destination index is one less than what the system gives up
        if destinationIndexPath.item > sourceIndexPath.item{
            destinationIndexPath = IndexPath(item: destinationIndexPath.item - 1, section: destinationIndexPath.section)
        }
        
        guard let destinationProductLayout = (collectionView.cellForItem(at: destinationIndexPath) as? PhotobookCollectionViewCell)?.bookView.leftPageView.productLayout,
            let destinationProductLayoutIndex = ProductManager.shared.productLayouts.index(where: { $0 === destinationProductLayout })
            else { return }
        
        if sourceIndexPath.item < destinationIndexPath.item {
            if !sourceProductLayout.layout.isDoubleLayout {
                ProductManager.shared.productLayouts.move(sourceProductLayoutIndex + 1, destinationProductLayoutIndex + 1)
            }
            ProductManager.shared.productLayouts.move(sourceProductLayoutIndex, destinationProductLayoutIndex)
        }
        else {
            ProductManager.shared.productLayouts.move(sourceProductLayoutIndex, destinationProductLayoutIndex)
            if !sourceProductLayout.layout.isDoubleLayout {
                ProductManager.shared.productLayouts.move(sourceProductLayoutIndex + 1, destinationProductLayoutIndex + 1)
            }
        }
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        }, completion: { _ in
            self.interactingItemIndexPath = nil
            self.proposedDropIndexPath = nil
        })
        
        for item in coordinator.items{
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        collectionView.cancelInteractiveMovement()
        interactingItemIndexPath = nil
        proposedDropIndexPath = nil
    }
    
}

extension PhotobookViewController: PhotobookPageViewDelegate {
    // MARK: PhotobookViewDelegate

    func didTapOnPage(index: Int) {
        // TODO: Edit page
        print("Tapped on page:\(index)")
    }

}

extension PhotobookViewController: PhotobookCollectionViewCellDelegate {
    // MARK: PhotobookCollectionViewCellDelegate
    
    func didTapOnPlusButton(at foldIndex: Int) {
        let indexPath = IndexPath(item: foldIndex, section: 1)
        
        guard let productLayout = (collectionView.cellForItem(at: indexPath) as? PhotobookCollectionViewCell)?.leftPageView.productLayout else { return }
        
        // Insert new page above the tapped one
        ProductManager.shared.addPages(above: productLayout)
        collectionView.insertItems(at: [indexPath])
    }
}
