//
//  PhotoBookViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var ctaButtonContainer: UIView!
    var selectedAssetsManager: SelectedAssetsManager?
    var photobook: String = "210x210 mm" //TODO: Replace with photobook model
    var titleLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        setupTitleView()
        
        selectedAssetsManager?.preparePhotoBookAssets(minimumNumberOfAssets: 21) //TODO: Replace with product minimum
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
        //TODO: Enter rearrange mode
        print("Tapped Rearrange")
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
            
            let rightPage = (cell.bookView as? PhotoBookDoublePageView)?.rightPage
            
            rightPage?.delegate = self
            page.delegate = self
            
            // First and last pages of the book are courtesy pages, no photos on them
            switch indexPath.item{
            case 0:
                page.index = nil
                rightPage?.index = 1
            case collectionView.numberOfItems(inSection: 1) - 1: // Last page
                page.index = (selectedAssetsManager?.assets.count ?? 0) - 1
                rightPage?.index = nil
            default:
                //TODO: Get indexes from Photobook model, because full width layouts means that we can't rely on indexPaths
                page.index = indexPath.item * 2
                rightPage?.index = indexPath.item * 2 + 1
            }
            
            load(page: page, size: imageSize)
            
            if rightPage != nil{
                load(page: rightPage!, size: imageSize)
            }

            return cell
        
        }
    }
    
}

extension PhotoBookViewController: UICollectionViewDelegate{
    // MARK: - UICollectionViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navBar = navigationController?.navigationBar as? PhotoBookNavigationBar else { return }
        
        navBar.effectView.alpha = scrollView.contentOffset.y <= -(UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.frame.height ?? 0)) ? 0 : 1
    }
    
}

extension PhotoBookViewController: PhotoBookViewDelegate{
    // MARK: - PhotoBookViewDelegate
    
    func didTapOnPage(index: Int) {
        print("Tapped on page:\(index)")
    }
    
}
