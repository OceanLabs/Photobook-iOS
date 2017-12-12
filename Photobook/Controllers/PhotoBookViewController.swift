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
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.dropDelegate = self
        }
    }
    @IBOutlet weak var ctaButtonContainer: UIView!
    var selectedAssetsManager: SelectedAssetsManager?
    var photobook: String = "210x210 mm" //TODO: Replace with photobook model
    var titleLabel: UILabel?
    private var dragItemIndexPath: IndexPath?
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
                (photobookCell.bookView.interactions.first as? UIDragInteraction)?.isEnabled = isRearranging
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        setupTitleView()
        
        selectedAssetsManager?.preparePhotoBookAssets(minimumNumberOfAssets: 21) //TODO: Replace with product minimum
        
        collectionViewBottomConstraint.constant = -self.view.frame.height * (reverseRearrageScale - 1)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bottomInset = isRearranging ? (ctaButtonContainer.frame.size.height - view.safeAreaInsets.bottom) * reverseRearrageScale : ctaButtonContainer.frame.size.height - view.safeAreaInsets.bottom - collectionViewBottomConstraint.constant
        
        let topInset = isRearranging ? (navigationController?.navigationBar.frame.maxY ?? 0) * (1 - Constants.rearrageScale) : 0
                
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: collectionView.contentInset.left, bottom: bottomInset, right: collectionView.contentInset.right)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
    }
    
    func setupTitleView() {
        let titleLabel = UILabel()
        self.titleLabel = titleLabel
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center;
        titleLabel.text = photobook //TODO: Replace with product name
        
        let chevronView = UIImageView(image: UIImage(named:"chevron-down"))
        chevronView.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, chevronView])
        stackView.spacing = 5
        
        stackView.isUserInteractionEnabled = true;
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnTitle)))
        
        navigationItem.titleView = stackView;
    }
    
    @objc func didTapOnTitle() {
        // TODO: Get these from somewhere
        let photobooks = ["210x210 mm", "B", "C", "D"]
        
        let alertController = UIAlertController(title: nil, message: NSLocalizedString("Photobook/ChangeSizeTitle", value: "Changing the size keeps your layout intact", comment: "Information when the user wants to change the photo book's size"), preferredStyle: .actionSheet)
        for photobook in photobooks{
            alertController.addAction(UIAlertAction(title: photobook, style: .default, handler: { [weak welf = self] (_) in
                welf?.titleLabel?.text = photobook
            }))
        }
        
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func didTapRearrange(_ sender: UIBarButtonItem) {
        isRearranging = !isRearranging
    }
    
    @IBAction func didTapCheckout(_ sender: UIButton) {
        print("Tapped Checkout")
    }
    
    @IBAction func didTapOnSpine(_ sender: UITapGestureRecognizer) {
        print("Tapped on spine")
    }
    
    func load(page: PhotoBookPageView, size: CGSize){
        page.setImage(image: nil)
        page.pageLayout = nil
        
        guard let index = page.index else {
            page.contentView.isHidden = true
            return
        }
        page.contentView.isHidden = false
        
        let asset = selectedAssetsManager?.assets[index]
        
        asset?.image(size: size, completionHandler: { (image, _) in
            guard page.index == index, let image = image else { return }
                        
            page.setImage(image: image, contentMode: (asset as? PlaceholderAsset) == nil ? .scaleAspectFill : .center)
        })
    }
    
}

extension PhotoBookViewController: UICollectionViewDataSource{
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section{
        case 1:
            //TODO: Get this from Photobook model
            return ((selectedAssetsManager?.assets.count ?? 0 ) + 1) / 2
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
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as? PhotoBookCoverCollectionViewCell,
                let page = cell.coverView.page
                else { return UICollectionViewCell() }
            
            page.index = 0
            page.delegate = self
            load(page: page, size: imageSize)
            
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotoBookCollectionViewCell,
                let page = cell.bookView.page
                else { return UICollectionViewCell() }
            
            cell.bookView.indexPath = indexPath
            cell.obscuringView.isHidden = indexPath != dragItemIndexPath
            cell.delegate = self
            
            let rightPage = (cell.bookView as? PhotoBookDoublePageView)?.rightPage
            
            rightPage?.delegate = self
            page.delegate = self
            
            // First and last pages of the book are courtesy pages, no photos on them
            switch indexPath.item{
            case 0:
                page.index = nil
                rightPage?.index = 1
                cell.plusButton.isHidden = true
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                page.index = (selectedAssetsManager?.assets.count ?? 0) - 1
                rightPage?.index = nil
                cell.plusButton.isHidden = false
            default:
                //TODO: Get indexes from Photobook model, because full width layouts means that we can't rely on indexPaths
                page.index = indexPath.item * 2
                rightPage?.index = indexPath.item * 2 + 1
                cell.plusButton.isHidden = false
                
                // Add drag interaction
                if cell.bookView.interactions.count == 0{
                    let dragInteraction = UIDragInteraction(delegate: self)
                    cell.bookView.addInteraction(dragInteraction)
                    cell.clipsToBounds = false
                }
                (cell.bookView.interactions.first as? UIDragInteraction)?.isEnabled = isRearranging
            }
            
            load(page: page, size: imageSize)
            
            if rightPage != nil{
                load(page: rightPage!, size: imageSize)
            }

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
    
}

extension PhotoBookViewController: UIDragInteractionDelegate {
    // MARK: - UIDragInteractionDelegate
    
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let bookView = interaction.view as? PhotoBookView,
            let indexPath = bookView.indexPath
            else { return [] }
        
        dragItemIndexPath = indexPath
        
        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        guard let bookView = interaction.view as? PhotoBookView,
            let indexPath = bookView.indexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoBookCollectionViewCell
            else { return }
        
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
        guard let indexPath = dragItemIndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoBookCollectionViewCell else { return }
        
        animator.addCompletion({(_) in
            cell.obscuringView.isHidden = true
        })
    }
    
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        dragItemIndexPath = nil

        guard let bookView = interaction.view as? PhotoBookView,
            let indexPath = bookView.indexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoBookCollectionViewCell else { return }
        
        cell.obscuringView.isHidden = true
    }
    
}

extension PhotoBookViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal{
        
        // Prevent dragging to the same indexPath and the next
        guard
            let index = session.localDragSession?.localContext as? Int,
            let indexPath = destinationIndexPath,
            index != indexPath.item,
            index + 1 != indexPath.item
            else { return UICollectionViewDropProposal(operation: .cancel)}
        
        // Disallow dragging to the first and last pages and cover.
        guard
            collectionView.cellForItem(at: indexPath) as? PhotoBookCoverCollectionViewCell == nil,
            indexPath.item != 0,
            indexPath.item != collectionView.numberOfItems(inSection: 1) - 1 // Last Page
            else { return UICollectionViewDropProposal(operation: .forbidden) }
        
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
    }
}

extension PhotoBookViewController: PhotoBookViewDelegate {
    // MARK: - PhotoBookViewDelegate
    
    func didTapOnPage(index: Int) {
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
