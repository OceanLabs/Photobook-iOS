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
        static let cellSideMargin: CGFloat = 10.0
    }

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet{
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        guard let photobook = ProductManager.shared.products?.first else {
            loadProducts()
            return
        }
        
        setup(with: photobook)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var bottomInset = ctaButtonContainer.frame.size.height
        
        if #available(iOS 11.0, *) {
            bottomInset -= view.safeAreaInsets.bottom
        }
        
        collectionView.contentInset = UIEdgeInsets(top: collectionView.contentInset.top, left: collectionView.contentInset.left, bottom: bottomInset, right: collectionView.contentInset.right)
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
        //TODO: Enter rearrange mode
        print("Tapped Rearrange")
    }
    
    @IBAction private func didTapCheckout(_ sender: UIButton) {
        print("Tapped Checkout")
    }
    
    @IBAction private func didTapOnSpine(_ sender: UITapGestureRecognizer) {
        print("Tapped on spine")
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
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as? PhotobookCollectionViewCell
                else { return UICollectionViewCell() }
            
            if let photobook = ProductManager.shared.product{
                cell.configurePageAspectRatio(photobook.coverSizeRatio)
            }
            
            cell.leftPageView.index = 0
            cell.leftPageView.delegate = self
            cell.leftPageView.load(size: imageSize)
            
            return cell
        default:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "doublePageCell", for: indexPath) as? PhotobookCollectionViewCell
                else { return UICollectionViewCell() }
            
            cell.widthConstraint.constant = view.bounds.size.width - Constants.cellSideMargin * 2.0
            
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
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                cell.leftPageView.index = ProductManager.shared.productLayouts.count - 1
                cell.rightPageView?.index = nil
            default:
                //TODO: Get indexes from Photobook model, because full width layouts means that we can't rely on indexPaths
                cell.leftPageView.index = indexPath.item * 2
                cell.rightPageView?.index = indexPath.item * 2 + 1
            }

            cell.leftPageView.load(size: imageSize)
            cell.rightPageView?.load(size: imageSize)

            return cell
        
        }
    }
}

extension PhotobookViewController: UICollectionViewDelegate {
    // MARK: UICollectionViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navigationController?.navigationBar as? PhotobookNavigationBar else { return }
        
        navBar.effectView.alpha = scrollView.contentOffset.y <= -(UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height ?? 0)) ? 0 : 1
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
