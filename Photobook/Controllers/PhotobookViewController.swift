//
//  PhotoBookViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookViewController: UIViewController {
    
    private struct Constants {
        static let rearrageScale: CGFloat = 0.8
    }
    private var reverseRearrageScale: CGFloat {
        return 1 + (1 - Constants.rearrageScale) / Constants.rearrageScale
    }

    @IBOutlet weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet{
            collectionView.dropDelegate = self
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = UICollectionViewFlowLayoutAutomaticSize
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.estimatedItemSize = CGSize(width: 100, height: 100)
        }
    }
    @IBOutlet weak var ctaButtonContainer: UIView!
    var selectedAssetsManager: SelectedAssetsManager?
    var photobook: String = "210x210 mm" //TODO: Replace with photobook model
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
                guard let photobookCell = cell as? PhotoBookCollectionViewCell else { continue }
                photobookCell.setIsRearranging(isRearranging)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        guard let assets = selectedAssetsManager?.selectedAssets,
            let photobook = ProductManager.shared.products?.first
            else { return }
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
        let titleLabel = UILabel()
        self.titleLabel = titleLabel
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center;
        titleLabel.text = ProductManager.shared.product?.name
        
        let chevronView = UIImageView(image: UIImage(named:"chevron-down"))
        chevronView.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        stackView.spacing = 5
        
        stackView.isUserInteractionEnabled = true;
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnTitle)))
        
        navigationItem.titleView = stackView;
    }
    
    @objc private func didTapOnTitle() {
        guard let photobooks = ProductManager.shared.products else { return }
        
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("Photobook/ChangeSizeTitle", value: "Changing the size keeps your layout intact", comment: "Information when the user wants to change the photo book's size"), preferredStyle: .actionSheet)
        for photobook in photobooks{
            alertController.addAction(UIAlertAction(title: photobook.name, style: .default, handler: { [weak welf = self] (_) in
                welf?.titleLabel?.text = photobook.name
                
                var assets = [Asset]()
                for layout in ProductManager.shared.productLayouts{
                    guard let asset = layout.asset else { continue }
                    assets.append(asset)
                }
                ProductManager.shared.setPhotobook(photobook, withAssets: assets)
                self.collectionView.reloadData()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("General/UI", value: "Cancel", comment: "Cancel a change"), style: .default, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }

    @IBAction private func didTapRearrange(_ sender: UIBarButtonItem) {
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
    
    private func load(page: PhotoBookPageView?, size: CGSize) {
        guard let page = page else { return }
        
        page.setImage(image: nil)
        
        guard let index = page.index, index < ProductManager.shared.productLayouts.count else {
            page.isHidden = true
            return
        }
        page.isHidden = false
        
        let productLayout = ProductManager.shared.productLayouts[index]
        if productLayout.layout.imageLayoutBox != nil {
            let asset = ProductManager.shared.productLayouts[index].asset
            productLayout.asset = asset
            asset?.image(size: size, completionHandler: { (image, _) in
                guard page.index == index, let image = image else { return }
                
                page.setImage(image: image, contentMode: (asset as? PlaceholderAsset) == nil ? .scaleAspectFill : .center)
            })
        }
        page.productLayout = productLayout
        
    }
    
    // MARK: - UIMenuController actions
    
    @objc func copyPages() {
        // TODO: copy
    }
    
    @objc func pastePages() {
        // TODO: paste
    }
    
    @objc func deletePages() {
        // TODO: delete
    }
    
    @objc func menuDidHide() {
            interactingItemIndexPath = nil
    }
    
}

extension PhotoBookViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
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
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as? PhotoBookCoverCollectionViewCell
                else { return UICollectionViewCell() }
            
            if let photobook = ProductManager.shared.product{
                cell.configurePageAspectRatio(photobook.coverSizeRatio)
            }
            
            cell.leftPageView.index = 0
            cell.leftPageView.delegate = self
            load(page: cell.leftPageView, size: imageSize)
            
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotoBookCollectionViewCell
                else { return UICollectionViewCell() }
            
            cell.widthConstraint.constant = view.bounds.size.width - 20
            cell.bookView.indexPath = indexPath
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
                cell.leftPageView.index = nil
                cell.rightPageView?.index = 1
                cell.plusButton.isHidden = true
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                cell.leftPageView.index = ProductManager.shared.productLayouts.count - 1
                cell.rightPageView?.index = nil
                cell.plusButton.isHidden = false
            default:
                //TODO: Get indexes from Photobook model, because full width layouts means that we can't rely on indexPaths
                cell.leftPageView.index = indexPath.item * 2
                cell.rightPageView?.index = indexPath.item * 2 + 1
                cell.plusButton.isHidden = false
                
                // Add drag interaction
                if cell.bookView.interactions.count == 0{
                    let dragInteraction = UIDragInteraction(delegate: self)
                    cell.bookView.addInteraction(dragInteraction)
                    cell.clipsToBounds = false
                }
                cell.setIsRearranging(isRearranging)
            }

            load(page: cell.leftPageView, size: imageSize)
            load(page: cell.rightPageView, size: imageSize)

            return cell
        
        }
    }
    
}

extension PhotoBookViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navigationController?.navigationBar as? PhotoBookNavigationBar else { return }
        
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
        
        let copyItem = UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemCopyTitle", value: "Copy", comment: "Copy/Paste interaction"), action: #selector(copyPages))
        let pasteItem = UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemPasteTitle", value: "Paste", comment: "Copy/Paste interaction"), action: #selector(pastePages))
        let deleteItem = UIMenuItem(title: NSLocalizedString("PhotoBook/MenuItemDeleteTitle", value: "Delete", comment: "Delete a page from the photobook"), action: #selector(deletePages))
        UIMenuController.shared.menuItems = [copyItem, pasteItem, deleteItem]
        UIMenuController.shared.setMenuVisible(true, animated: true)
    }
    
}

extension PhotoBookViewController: UIDragInteractionDelegate {
    // MARK: - UIDragInteractionDelegate
    
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let bookView = interaction.view as? PhotobookView,
            let indexPath = bookView.indexPath
            else { return [] }
        
        interactingItemIndexPath = indexPath
        
        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        guard let bookView = interaction.view as? PhotobookView,
            let indexPath = bookView.indexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoBookCollectionViewCell
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
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoBookCollectionViewCell else { return }
        
        animator.addCompletion({(_) in
            cell.obscuringView.isHidden = true
        })
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        interactingItemIndexPath = nil

        guard let bookView = interaction.view as? PhotobookView,
            let indexPath = bookView.indexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoBookCollectionViewCell else { return }
        
        cell.obscuringView.isHidden = true
    }
    
}

extension PhotoBookViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal{
        
        // Prevent dragging to the same indexPath, the next, the cover and the first and last pages
        guard
            let draggingIndex = interactingItemIndexPath?.item,
            let dropIndexPath = destinationIndexPath,
            draggingIndex != dropIndexPath.item,
            draggingIndex + 1 != dropIndexPath.item,
            collectionView.cellForItem(at: dropIndexPath) as? PhotoBookCoverCollectionViewCell == nil,
            dropIndexPath.item != 0,
            dropIndexPath.item != collectionView.numberOfItems(inSection: 1) - 1 // Last Page
            else {
                if proposedDropIndexPath != nil {
                    return UICollectionViewDropProposal(operation:.move, intent: .unspecified)
                }
                return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
        }
        
        proposedDropIndexPath = dropIndexPath
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let sourceIndexPath = interactingItemIndexPath,
            let destinationIndexPath = proposedDropIndexPath
            else { return }
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        }, completion: { _ in
            self.interactingItemIndexPath = nil
            self.proposedDropIndexPath = nil
        })
    }
}

extension PhotoBookViewController: PhotoBookPageViewDelegate {
    // MARK: - PhotoBookViewDelegate

    func didTapOnPage(index: Int) {
        // TODO: Edit page
        print("Tapped on page:\(index)")
    }

}

extension PhotoBookViewController: PhotoBookCollectionViewCellDelegate {
    // MARK: - PhotoBookCollectionViewCellDelegate
    
    func didTapOnPlusButton(at indexPath: IndexPath?) {
        //TODO: Add page
        print("Add page")
    }
}
